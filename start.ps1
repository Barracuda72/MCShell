##### User-editable settings

# Java and Jar paths
$JAVA = "C:\Program Files\ojdkbuild\java-1.8.0-openjdk-1.8.0.171-1\bin\java.exe"
$JAR = "C:\Program Files\ojdkbuild\java-1.8.0-openjdk-1.8.0.171-1\bin\jar.exe"

# Allocated memory
$MC_MEMORY="3072m"

# Username (optional; comment out / leave empty for auto-detection from $MC_PROFILE)
$MC_USERNAME="Player"

# UUID (optional; can be read from $MC_PROFILE or generated automatically)
$MC_UUID="12345678-1234-1234-1234-1234567890AB"

# Minecraft directory (change in case script isn't in there)
$MC_DIR="${PWD}"

# Uncomment this line if you haven't purchased the game
# $DEMO="--demo"

##### Other settings

# JSON that contains profile information
$MC_PROFILE = "launcher_profiles.json"

# Main java class
$MC_MAIN_CLASS = "net.minecraft.client.main.Main"

##### End of settings

# Get current game and assets versions
$VERSION = (Get-ChildItem .\versions\ | Sort-Object { [version]($_.Name) } | Foreach-Object {$_.Name})[-1]
$ASS_VER = (Get-ChildItem .\assets\indexes\ | Sort-Object { [version]($_.Name -replace '^(.*\d)\.json', '$1') } | Foreach-Object {$_.Name})[-1] -replace ".json", ""

# Set versioned variables
$MAIN_JAR = "versions/${VERSION}/${VERSION}.jar"
$MAIN_JSON = "versions/${VERSION}/${VERSION}.json"
$NAT_PREFIX = "versions/${VERSION}/${VERSION}-natives"

# Get all java libraries (file names)
# Create list of libraries for classpath
$LIBS = (Get-Content $MAIN_JSON | ConvertFrom-Json | select -expand libraries | select -expand downloads | select -expand artifact | select -expand url | Foreach-object { $_ -replace "https:\/\/[a-z.]*", "libraries" }) -Join ";"
# Get all native libraries (file names)
# Create list of natives for further processing
$NATIVES = Get-Content $MAIN_JSON | ConvertFrom-Json | select -expand libraries | Where-Object {Get-Member -inputobject $_ -name "natives" -Membertype Properties} | select -expand downloads | select -expand classifiers | Where-Object {Get-Member -inputobject $_ -name "natives-windows" -Membertype Properties} | select -expand natives-windows | select -expand url | Foreach-Object { $_ -replace "https:\/\/[a-z.]*", "${pwd}/libraries" }

# TODO: hardcoded natives path
$NAT_DIR = "natives"

# TODO: don't remove it every time
Remove-Item $NAT_DIR -Recurse -Force
New-Item $NAT_DIR -ItemType Directory -Force | Out-Null

# Unpack natives
# Note: Expand-Archive wouldn't work on .jar
Push-Location $NAT_DIR
$NATIVES | ForEach-Object { & "${JAR}" "xf"  $_ }
Pop-Location

# Set username if not specified
# TODO
#$MC_USERNAME = "Player"

# If UUID wasn't already specified and profile file exists, read UUID from it
# TODO

# In the case we don't have UUID, generate plausible one
# This is not required and can simply be zeroed out, but just looks good
# BEWARE: UUID is used in-game for several purposes (like tamed wolf ownership), so with different UUID you will lose all those stuff!
# TODO

# Some log stuff
Write-Host "Starting Minecraft ${VERSION} (assets ${ASS_VER})..."
Write-Host "Player ${MC_USERNAME} (UUID ${MC_UUID})"

# Run game
& "${JAVA}" "-cp" "${LIBS};${MAIN_JAR}" "-Xmx${MC_MEMORY}" "-Xms${MC_MEMORY}" `
  "-Djava.library.path=${NAT_DIR}" "${MC_MAIN_CLASS}" `
  "--version" "${VERSION}" `
  "--username" "${MC_USERNAME}" `
  "--gameDir" "${MC_DIR}" `
  "--assetsDir" "${MC_DIR}/assets" `
  "--assetIndex" "${ASS_VER}" `
  "--uuid" "${MC_UUID}" `
  "--accessToken" "null" `
  "--userProperties" "{}" `
  "--userType" "legacy" "${DEMO}"
