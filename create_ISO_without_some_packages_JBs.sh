#!/bin/bash
#
# Autor= João Batista Ribeiro
# Bugs, Agradecimentos, Criticas "construtivas"
# Mande me um e-mail. Ficarei Grato!
# e-mail: joao42lbatista@gmail.com
#
# Este programa é um software livre; você pode redistribui-lo e/ou
# modifica-lo dentro dos termos da Licença Pública Geral GNU como
# publicada pela Fundação do Software Livre (FSF); na versão 2 da
# Licença, ou (na sua opinião) qualquer versão.
#
# Este programa é distribuído na esperança que possa ser útil,
# mas SEM NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a
# qualquer MERCADO ou APLICAÇÃO EM PARTICULAR.
#
# Veja a Licença Pública Geral GNU para mais detalhes.
# Você deve ter recebido uma cópia da Licença Pública Geral GNU
# junto com este programa, se não, escreva para a Fundação do Software
#
# Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# Script: Create a ISO without some package from a local directory that you don't want
#
# Last update: 13/06/2017
#
# Tip: Add the packages you want in the packagesList
# Need one space before add more
#
echo -e "\nThis script create a ISO file from a clone folder of Slackware"

folderWork=$1
if [ "$folderWork" == '' ]; then
    echo -e "\nError: You need pass the folder to work\n"
elif [ ! -d "$folderWork" ]; then
    echo -e "\nError: The dictory \"$folderWork\" not exist\n"
else
    ## Add packages that you want in the packagesList
    ## Need one space before add more
    ## For example: Remove ktorrent
    # packagesList="$packagesList ktorrent libktorrent"

    # Remove games
    packagesList="palapeli bomber granatier
    kblocks ksnakeduel kbounce kbreakout kgoldrunner
    kspaceduel kapman kolf kollision kpat lskat blinken
    khangman pairs ktuberling kdiamond ksudoku kubrick
    picmi bovo kblackbox kfourinline kmahjongg kreversi
    ksquares kigo kiriki kshisen gnuchess katomic
    kjumpingcube kmines knetwalk killbots klickety
    klines konquest ksirk knavalbattle kanagram amor kajongg"

    # Remove XFCE or/and KDE
    echo -en "\nLeave XFCE or KDE?\n(1) Leave KDE, (2) Leave XFCE, (3) Remove XFCE and KDE (hit enter to Leave KDE): "
    read -r leaveXGUI
    if [ "$leaveXGUI" == '1' ] || [ "$leaveXGUI" == '' ]; then
        packagesListTmp=" xfce"
    elif [ "$leaveXGUI" == '2' ]; then
        packagesListTmp=" kde" # Also remove kde-l10n-
    elif [ "$leaveXGUI" == '3' ]; then
        packagesListTmp=" kde xfce" # Also remove kde-l10n-
    fi

    echo -e "\nWill remove \"$packagesListTmp\""
    packagesList="$packagesList $packagesListTmp"

    # Remove servidor X - Leave fluxbox # Safe propose
    packagesList="$packagesList twm blackbox windowmaker fvwm"

    # Remove kopote
    packagesList="$packagesList kdenetwork-filesharing kdenetwork-strigi-analyzers kopete"

    # Remove nepomuk
    packagesList="$packagesList nepomuk-core nepomuk-widgets"

    # Remove akonadi
    packagesList="$packagesList akonadi"

    # Remove kde-l10n- - others languages for the KDE
    packagesList="$packagesList kde-l10n-"

    echo -e "\nRemove \"gnome packages\"? \"gcr- polkit-gnome gnome-themes libgnome-keyring gnome-keyring\""
    echo "Recommended if you remove XFCE, but leave if you not remove XFCE."
    echo -n "(y)es to remove or (n)ot remove (hit enter to remove): "
    read -r removeGnomePackages
    if [ "$removeGnomePackages" == 'y' ] || [ "$removeGnomePackages" == '' ]; then
        # Remove gnome "packages" # gcr- to not remove libgcrypt
        packagesList="$packagesList gcr- polkit-gnome gnome-themes libgnome-keyring gnome-keyring"
        echo -en "\nR"
    else
        echo -en "\nNot r"
    fi
    echo -e "emoving \"gnome packages\"\n"

    # Remove other packages
    packagesList="$packagesList seamonkey pidgin xchat dragon thunderbird kplayer
    calligra bluedevil blueman bluez-firmware bluez xine-lib xine-ui
    emacs amarok audacious
    vim-gvim vim sendmail-cf sendmail xpdf tetex-doc tetex kget"

    ## Virtualbox need # Remove kernel-source
    #packagesList="$packagesList kernel-source"

    countI='0'
    echo -e "\nPackages that will be removed:\n"
    for packageName in $packagesList; do
        echo -n "$packageName "
        if [ "$countI" == "10" ]; then
            echo
            countI='0'
        else
            ((countI++))
        fi
    done

    echo -en "\n\nWant continue? (y)es or (n)o: "
    read -r continueOrNot
    if [ "$continueOrNot" != 'y' ]; then
        echo -e "\nJust exiting by local choice\n"
        exit 0
    fi

    folderWork=${folderWork//\//} # Remove the / in the end
    cd "$folderWork" || exit

    filesIgnoredInTheISO="../0_filesIgnoredInTheISO.txt"
    mkisofsExcludeList="../1_mkisofsExcludeList.txt"
    filesNotFound="../2_filesNotFound.txt"

    rm "$filesIgnoredInTheISO" "$mkisofsExcludeList" "$filesNotFound" 2> /dev/null

    for packageName in $packagesList; do
        echo -e "\nLooking for \"$packageName\""
        resultFind=$(find . | grep "$packageName" | grep -E ".t.z$|.asc$|.txt$")

        if [ "$resultFind" == '' ]; then
            echo "Not found: \"$packageName\"" | tee -a "$filesNotFound"
        else
            echo -e "Files ignored with the pattern: \"$packageName\"\n$resultFind\n" | tee -a "$filesIgnoredInTheISO"
            echo "$resultFind" | rev | cut -d '/' -f1 | rev >> "$mkisofsExcludeList"
        fi
    done

    echo -en "\nWant create a ISO file from work folder?\n(y)es - (n)o (press enter to no): "
    read -r generateISO

    isoFileName="${folderWork}_SelectedPkgs_date_$(date +%d_%m_%Y)"

    if [ "$generateISO" == 'y' ]; then
        cd .. || exit

        mkisofsExcludeList=${mkisofsExcludeList:3} # Remove ../ from the path
        filesNotFound=${filesNotFound:3}
        filesIgnoredInTheISO=${filesIgnoredInTheISO:3}

        echo -e "\nCreating ISO file. Please wait...\n"
        mkisofs -exclude-list "$mkisofsExcludeList" -pad -r -J -o "${isoFileName}.iso" "$folderWork/"

        # -exclude-list FILE - File with list of file names to exclude
        # -pad                 Pad output to a multiple of 32k (default)
        # -r                   Generate rationalized Rock Ridge directory information
        # -J                   Generate Joliet directory information
        # -o                   Set output file name

        echo -e "\n\nThe ISO file \"$isoFileName.iso\" was generated by the folder \"$folderWork/\"\n"
    else
        echo -e "\n\nExiting...\n\nIf you want create a ISO file, use:\nmkisofs -exclude-list \"$mkisofsExcludeList\" -pad -r -J -o \"${isoFileName}.iso\" \"$folderWork/\"\n"
    fi

    echo -e "\nTake a look in the files:\n"
    echo "$(pwd)/"
    echo -e "\t\t $(find $mkisofsExcludeList | rev | cut -d '/' -f1 | rev)"
    echo -e "\t\t $(find $filesIgnoredInTheISO | rev | cut -d '/' -f1 | rev)"
    echo -e "\t\t $(find $filesNotFound 2> /dev/null | rev | cut -d '/' -f1 | rev)"
fi