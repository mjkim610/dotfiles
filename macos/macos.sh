#!/bin/zsh

# Custom dotfile based on https://github.com/echohack/macbot and https://github.com/mathiasbynens/dotfiles

###############################################################################
# Bootstrapping                                                               #
###############################################################################

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Current User
user=$(id -un)

# Script's color palette
reset="\033[0m"
highlight="\033[42m\033[97m"
dot="\033[33m▸ $reset"
dim="\033[2m"
bold="\033[1m"

headline() {
    printf "${highlight} %s ${reset}\n" "$@"
}
step() {
    echo "${dot}$@"
}
run() {
    echo "${dim}▹ $@ $reset"
    eval $@
}

echo ""
headline " Let's secure and tweak your Mac."
echo ""
echo "Modifying settings for user: $user."
# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
if [ $(sudo -n uptime 2>&1|grep "load"|wc -l) -eq 0 ]
then
    step "Some of these settings are system-wide, therefore we need your permission."
    sudo -v
    echo ""
fi

###############################################################################
# General UI/UX                                                               #
###############################################################################

step "Setting your computer name (as done via System Preferences → Sharing)."
echo "What would you like it to be? $bold"
read computer_name
echo "$reset"
run sudo scutil --set ComputerName "'$computer_name'"
run sudo scutil --set HostName "'$computer_name'"
run sudo scutil --set LocalHostName "'$computer_name'"
run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "'$computer_name'"

echo "Disable Resume system-wide"
# None seem to work in Sierra
#run defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Make the file owned by root (otherwise the OS will just replace it)
#run sudo chown root ~/Library/Preferences/ByHost/com.apple.loginwindow*
# Remove all permissions, so it can't be read or written to
#run sudo chmod 000 ~/Library/Preferences/ByHost/com.apple.loginwindow*

#echo "Disable the warning when changing a file extension."
#run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

echo "Disable automatic capitalization, smart dashes, automatic period substitution, and smart quotes"
run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

echo "Disable auto-correct"
run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "Disable mouse enlargement with jiggle."
run defaults write ~/Library/Preferences/.GlobalPreferences CGDisableCursorLocationMagnification -bool true

echo "Always show scrollbars"
# Possible values: `WhenScrolling`, `Automatic` and `Always`
run defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

echo "Disable the focus ring animation"
run defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

echo "Use the dark theme."
run defaults write ~/Library/Preferences/.GlobalPreferences AppleInterfaceStyle -string "Dark"

echo "Set sidebar icon size to medium"
run defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

echo "Expand save panel by default"
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

echo "Expand print panel by default"
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Error in Sierra
#echo "Automatically quit printer app once the print jobs complete"
#run defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

echo "Set Help Viewer windows to non-floating (always-on-front) mode"
run defaults write com.apple.helpviewer DevMode -bool true

echo "Avoid creating .DS_Store files on network or USB volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Privacy                                                                     #
###############################################################################

echo "Disable Spotlight Suggestions, Bing Web Search, and other leaky data."
run python ./fix_leaky_data.py

echo "Set all network interfaces to use Google DNS."
run zsh ./use_google_dns.sh

echo "Disable Captive Portal Hijacking Attack."
run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

echo "Don't default to saving documents to iCloud."
run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

echo "Disable crash reporter."
run defaults write com.apple.CrashReporter DialogType none

echo "Enable Stealth Mode. Computer will not respond to ICMP ping requests or connection attempts from a closed TCP/UDP port."
run sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -bool true

echo "Disable wake on network access."
run sudo systemsetup -setwakeonnetworkaccess off

echo "Disable Bonjour multicast advertisements."
run sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool YES

###############################################################################
# Dock, Dashboard                                                             #
###############################################################################

echo "Change minimize/maximize window effect"
run defaults write com.apple.dock mineffect -string "scale"

echo "Minimize windows into their application’s icon"
run defaults write com.apple.dock minimize-to-application -bool true

#echo "Disable mission control animations."
#run defaults write com.apple.dock expose-animation-duration -float 0.0
# As of Sierra, there is no way to change expose animation.
# Workaround is to enable "Reduce Motion",
run defaults write com.apple.universalaccess reduceMotion -bool true

echo "Move dock to right side"
run defaults write com.apple.dock orientation -string "right"

echo "Auto-hide dock"
run defaults write com.apple.dock autohide -bool true

echo "Speed up the auto-hiding dock delay"
run defaults write com.apple.dock autohide-delay -float 0.1

echo "Set the icon size of Dock items to 36 pixels"
run defaults write com.apple.dock tilesize -int 45

echo "Make Dock icons of hidden applications translucent"
run defaults write com.apple.dock showhidden -bool true

echo "Don’t automatically rearrange Spaces based on most recent use"
run defaults write com.apple.dock mru-spaces -bool false

echo "Disable Dashboard"
run defaults write com.apple.dashboard mcx-disabled -bool true

###############################################################################
# SSD-specific tweaks                                                         #
###############################################################################

echo "Disable sudden motion sensor. (Not useful for SSDs)."
run sudo pmset -a sms 0

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

echo "Enable tap to click for this user and for the login screen"
run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
run defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
run defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

echo "Disable “natural” (Lion-style) scrolling"
run defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

echo "Disable press-and-hold for keys in favor of key repeat."
run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

echo "Set a fast keyboard repeat rate, after a good initial delay."
run defaults write NSGlobalDomain KeyRepeat -int 2
run defaults write NSGlobalDomain InitialKeyRepeat -int 25

echo "Set language and text formats"
# Note: if you’re in the US, replace to `USD`, `Inches`, `en_US`, and `false`.
run defaults write NSGlobalDomain AppleLanguages -array "en" "ko"
run defaults write NSGlobalDomain AppleLocale -string "ko_KR@currency=KRW"
run defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
run defaults write NSGlobalDomain AppleMetricUnits -bool true

###############################################################################
# Screen                                                                      #
###############################################################################

echo "Require password almost immediately after sleep or screen saver begins"
run defaults write com.apple.screensaver askForPassword -int 1
run defaults write com.apple.screensaver askForPasswordDelay -int 1

echo "Save screenshots in PNG format."
run defaults write com.apple.screencapture type -string png

echo "Save screenshots to user screenshots directory instead of desktop."
run mkdir ~/screenshots
run chmod -R +w ~/screenshots
run defaults write com.apple.screencapture location -string ~/screenshots

###############################################################################
# Finder                                                                      #
###############################################################################

echo "Set Desktop as the default location for new Finder windows"
# For other paths, use `PfLo` and `file:///full/path/here/`
run defaults write com.apple.finder NewWindowTarget -string "PfDe"
run defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

echo "Show icons for hard drives, servers, and removable media on the desktop"
run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
run defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
run defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
run defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

echo "Show the ~/Library folder."
run chflags nohidden ~/Library

echo "Show the /Volumes folder."
run sudo chflags nohidden /Volumes

echo "Show all filename extensions"
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Show status bar"
run defaults write com.apple.finder ShowStatusBar -bool true

echo "show path bar"
run defaults write com.apple.finder ShowPathbar -bool true

echo "Display full POSIX path as Finder window title"
run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

echo "Keep folders on top when sorting by name"
defaults write com.apple.finder _FXSortFoldersFirst -bool true

echo "Don't ask to use external drives as a Time Machine backup."
run defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

echo "Use list view in all Finder windows by default."
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
run defaults write com.apple.finder FXPreferredViewStyle -string '"Nlsv"'

###############################################################################
# Time Machine                                                                #
###############################################################################

echo "Prevent Time Machine from prompting to use new hard drives as backup volume"
run defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

echo "Disable local Time Machine backups"
run hash tmutil &> /dev/null && sudo tmutil disablelocal

###############################################################################
# Mac App Store                                                               #
###############################################################################

echo "Enable Mac App Store automatic updates."
run defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

echo "Check for Mac App Store updates daily."
run defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

echo "Download Mac App Store updates in the background."
run defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

echo "Install Mac App Store system data files & security updates."
run defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

echo "Turn on Mac App Store auto-update."
run defaults write com.apple.commerce AutoUpdate -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

# Security And Privacy Improvements
echo "Disable Safari from auto-filling sensitive data."
run defaults write ~/Library/Preferences/com.apple.Safari AutoFillCreditCardData -bool false
run defaults write ~/Library/Preferences/com.apple.Safari AutoFillFromAddressBook -bool false
run defaults write ~/Library/Preferences/com.apple.Safari AutoFillMiscellaneousForms -bool false
run defaults write ~/Library/Preferences/com.apple.Safari AutoFillPasswords -bool false

echo "Disable Safari from automatically opening files."
run defaults write ~/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads -bool false

echo "Always block cookies and local storage in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari BlockStoragePolicy -bool false

echo "Enable Safari warnings when visiting fradulent websites."
run defaults write ~/Library/Preferences/com.apple.Safari WarnAboutFraudulentWebsites -bool true

echo "Disable javascript in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari WebKitJavaScriptEnabled -bool false

echo "Block popups in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false
run defaults write ~/Library/Preferences/com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false

echo "Disable plugins and extensions in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2WebGLEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari WebKitPluginsEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari ExtensionsEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari PlugInFirstVisitPolicy PlugInPolicyBlock
run defaults write ~/Library/Preferences/com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
run defaults write ~/Library/Preferences/com.apple.Safari WebKitJavaEnabled -bool false

echo "Safari should treat SHA-1 certificates as insecure."
run defaults write ~/Library/Preferences/com.apple.Safari TreatSHA1CertificatesAsInsecure -bool true

echo "Disable pre-loading websites with high search rankings."
run defaults write ~/Library/Preferences/com.apple.Safari PreloadTopHit -bool false

echo "Disable Safari search engine suggestions."
run defaults write ~/Library/Preferences/com.apple.Safari SuppressSearchSuggestions -bool true

echo "Enable Do-Not-Track HTTP header in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari SendDoNotTrackHTTPHeader -bool true

echo "Disable pdf viewing in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari WebKitOmitPDFSupport -bool true

echo "Display full website addresses in Safari."
run defaults write ~/Library/Preferences/com.apple.Safari ShowFullURLInSmartSearchField -bool true

echo "Disable spotlight universal search (don't send info to Apple)."
run defaults write com.apple.safari UniversalSearchEnabled -int 0

###############################################################################
# Mail                                                                        #
###############################################################################

echo "Disable loading remote content in emails in Apple Mail."
run defaults write ~/Library/Preferences/com.apple.mail-shared DisableURLLoading -bool true

echo "Send junk mail to the junk mail box in Apple Mail."
run defaults write ~/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail JunkMailBehavior -int 2

###############################################################################
# Photos                                                                      #
###############################################################################

echo "Prevent Photos from opening automatically when devices are plugged in"
run defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Kill affected applications                                                  #
###############################################################################

echo "Run one final check to make sure software is up to date."
run softwareupdate -i -a

run killall Dock
run killall Finder

headline "Some settings will not take effect until you restart your computer."
headline " Your Mac is setup and ready!"
