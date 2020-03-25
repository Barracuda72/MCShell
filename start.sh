#!/bin/bash

##### User-editable settings

# Allocated memory
MC_MEMORY=3072m

# Username (optional; comment out / leave empty for auto-detection from $MC_PROFILE)
MC_USERNAME=Player

# UUID (optional; can be read from $MC_PROFILE or generated automatically)
MC_UUID="12345678-1234-1234-1234-1234567890AB"

# Minecraft directory (change in case script isn't in there)
MC_DIR="${PWD}"

# Uncomment this line if you haven't purchased the game
# DEMO="--demo"

##### Other settings

# JSON that contains profile information
MC_PROFILE="launcher_profiles.json"

# Main java class
MC_MAIN_CLASS=net.minecraft.client.main.Main

##### End of settings

# Finds the most recent version of the elements in the specified directory
function latest()
{
  VERS=`ls -v $1 | tail -n 1 | sed 's/\.json//g'`;
  echo ${VERS}
}

# Get current game and assets versions
VERSION=$(latest versions)
ASS_VER=$(latest assets/indexes)

# Set versioned variables
MAIN_JAR=versions/${VERSION}/${VERSION}.jar
MAIN_JSON=versions/${VERSION}/${VERSION}.json
NAT_PREFIX=versions/${VERSION}/${VERSION}-natives

# Get all java libraries (file names)
LIB_FILES=`cat ${MAIN_JSON} | grep libraries | grep -v natives | cut -d'"' -f4`
# Get all java libraries (names without versions)
LIB_NAMES=`for x in ${LIB_FILES}; do x=$(dirname $x); x=$(dirname $x); x=$(basename $x); echo $x; done | sort -u`
# Create list of libraries for classpath
LIBS=`for x in ${LIB_NAMES}; do cat ${MAIN_JSON} | grep libraries | grep -v sources | grep -v "\-doc" | grep -v natives | cut -d'"' -f4 | sort -u | egrep "${x}/[0-9]" | tail -n 1; done | sed 's/https:\/\/[a-z.]*\//libraries\//g' | xargs echo | sed 's/ /:/g'`

# Get all native libraries (file names)
NAT_FILES=`cat ${MAIN_JSON} | grep natives | grep linux | grep url | cut -d'"' -f4`
# Get all native libraries (names without versions)
NAT_NAMES=`for x in ${NAT_FILES}; do x=$(dirname $x); x=$(dirname $x); x=$(basename $x); echo $x; done | sort -u`
# Create list of natives for further processing
NATIVES=`for x in ${NAT_NAMES}; do cat ${MAIN_JSON} | grep natives | grep linux | grep url | cut -d'"' -f4 | sort -u | egrep "${x}/[0-9]" | tail -n 1; done | sed 's/https:\/\/[a-z.]*\//libraries\//g'`

# Find existing natives directory, if any
NAT_DIR="`find ${NAT_PREFIX}-* -type d 2>/dev/null | grep -v META | tail -n 1`"

# If there's none, set the path for the new one
if [ "x" == "x${NAT_DIR}" ]; then
  NAT_DIR="${NAT_PREFIX}-`date +'%s'`"
fi

# If natives directory doesn't exists, create it and unpack all native libraries there
if [ ! -d ${NAT_DIR} ]; then
  mkdir -p ${NAT_DIR}
  for f in ${NATIVES}; do
    echo "Unpacking " $f;
    unzip -qq -o $f -x META-INF/* -d ${NAT_DIR};
  done;
fi

# Set username if not specified
if [ "x${MC_USERNAME}" = "x" ]; then
  if [ $# = 0 ]; then
    # If it's not provided on the command line, then determine from the profile (use the first one)
    MC_USERNAME=`cat ${MC_PROFILE} | grep -m 1 -i "name" | cut -d'"' -f4`;
    if [ "x${MC_USERNAME}" = "x" ]; then
      # If there's none, use default one
      MC_USERNAME=Player;
    fi;
  else
    MC_USERNAME=$1;
  fi;
fi

# If UUID wasn't already specified and profile file exists, read UUID from it
if [ "x${MC_UUID}" = "x" -a -f ${MC_PROFILE} ]; then
  MC_UUID=`cat ${MC_PROFILE} | grep userid | cut -d'"' -f4 | \
    sed -e \
    's/^\([[:xdigit:]]\{8\}\)\([[:xdigit:]]\{4\}\)\([[:xdigit:]]\{4\}\)\([[:xdigit:]]\{4\}\)/\1-\2-\3-\4-/g'`;
fi

# In case we don't have UUID, generate plausible one
# This is not required and can simply be zeroed out, but just looks good
# BEWARE: UUID is used in-game for several purposes (like tamed wolf ownership), so with different UUID you will lose all those stuff!
if [ "x${MC_UUID}" = "x" ]; then
  MC_UUID=`uuidgen -t`;
fi

# Some log stuff
echo "Starting Minecraft ${VERSION} (assets ${ASS_VER})..."
echo "Player ${MC_USERNAME} (UUID ${MC_UUID})"

# Run game
java -cp ${LIBS}:${MAIN_JAR} -Xmx${MC_MEMORY} -Xms${MC_MEMORY} \
  -Djava.library.path=${NAT_DIR} ${MC_MAIN_CLASS} \
  --version ${VERSION} \
  --username ${MC_USERNAME} \
  --gameDir ${MC_DIR} \
  --assetsDir ${MC_DIR}/assets \
  --assetIndex ${ASS_VER} \
  --uuid ${MC_UUID} \
  --accessToken null \
  --userProperties {} \
  --userType legacy ${DEMO}

