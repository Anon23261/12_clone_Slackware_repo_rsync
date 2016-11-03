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
# Script: Clone some Slackware repository to a local source
#
# Last update: 03/11/2016
#
# Tip: Use the file inside one "old" ISO to make less things to download

# Some colors for script output - Make it easier to follow
BLACK='\e[1;30m'
RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\033[0m' # reset/no color
BLUE='\e[1;34m'
PINK='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'

## To test color uncomment the next line
#echo -e "\n\tTest colors: $RED RED $WHITE WHITE $PINK PINK $BLACK BLACK $BLUE BLUE $GREEN GREEN $CYAN CYAN $NC NC\n"

mirrorSource="ftp://ftp.osuosl.org/.2/slackware/"

echo -e "$CYAN\nDefault mirror:$GREEN $mirrorSource$NC"

echo -en "$CYAN\nWant change the mirror?$NC\n(y)es - (n)o $GREEN(press enter to no):$NC "
read changeMirror

if [ "$changeMirror" == 'y' ]; then
    mirrorSource=''

    while echo "$mirrorSource" | grep -v -q -E "ftp|http"; do
        echo -en "$CYAN \nType the new mirror:$NC "
        read mirrorSource
    done

    echo -e "$CYAN\nNew mirror:$GREEN $mirrorSource$NC\n"
fi

echo -en "$CYAN\nWith version Slackware you want? $GREEN(press enter to 14.2):$NC "
read versioSlackware

if [ "$versioSlackware" == '' ]; then
    versioSlackware="14.2"
fi

echo -en "$CYAN\nWith arch you want?$NC\n(1) - 32 bits or (2) to 64 bits $GREEN(press enter to 64 bits):$NC "
read choosedArch

if [ "$choosedArch" == '1' ]; then
    choosedArch=''
else
    choosedArch="64"
fi

versionDownload=slackware$choosedArch-$versioSlackware

echo -en "$CYAN\nWant download the source code?$NC\n(y)es - (n)o $GREEN(press enter to no):$NC "
read downloadSource

echo -en "$CYAN\nWill download (by lftp) $GREEN\"$versionDownload\"$CYAN"
if [ "$downloadSource" == 'y' ]; then
    echo -en "$RED with $CYAN"
else
    echo -en "$RED without $CYAN"
fi
echo -e "the$BLUE source code$CYAN from $GREEN\"$mirrorSource\"$NC"

echo -en "$CYAN\nWant continue?$NC\n(y)es - (n)o $GREEN(press enter to yes):$NC "
read contineLftp

if [ "$contineLftp" == 'n' ]; then
    echo -e "$CYAN\nJust exiting by user choice\n$NC"
else
    if [ -e $versionDownload/ ]; then
        echo -e "$CYAN\nOlder folder download found ($GREEN$versionDownload/$CYAN)$NC"
        tmpMd5sumBeforeDownload=`mktemp`

        listOfFilesBeforeDownload=`find $versionDownload/ -type f -print`

        echo -en "$CYAN\nCreating a$BLUE md5sum$CYAN from files found (in folder $GREEN$versionDownload/$CYAN)$NC. Please wait..."
        for file in $listOfFilesBeforeDownload; do
            md5sum $file >> $tmpMd5sumBeforeDownload
        done
        echo -e "$CYAN\n\nThe$BLUE md5sum$RED (before the download)$CYAN was saved in the tmp file : $GREEN$tmpMd5sumBeforeDownload$NC"
    fi

    echo -en "$CYAN\nDownloading files$NC. Please wait...\n\n"

    if [ "$downloadSource" == 'y' ]; then
        lftp -c 'open '$mirrorSource'; mirror -c -e '$versionDownload'/'
        # -c continue a mirror job if possible
        # -e delete files not present at remote site
    else
        lftp -c 'open '$mirrorSource'; mirror -c -e --exclude source/ --exclude patches/source/ '$versionDownload'/'
    fi

    if [ "$tmpMd5sumBeforeDownload" != '' ]; then
        tmpMd5sumAfterDownload=`mktemp`

        listOfFilesAfterDownload=`find $versionDownload/ -type f -print`

        echo -en "$CYAN\nCreating a md5sum after the download ($versionDownload/)$NC\nPlease wait..."
        for file in $listOfFilesAfterDownload; do
            md5sum $file >> $tmpMd5sumAfterDownload
        done
        echo -e "$CYAN\n\nThe$BLUE md5sum$RED (after the download)$CYAN was saved in the tmp file : $GREEN$tmpMd5sumAfterDownload$NC"

        echo -en "$CYAN\nChecking the changes in the file$RED before$CYAN with$BLUE after$CYAN download $NC\nPlease wait..."
        changeResult=`diff -w $tmpMd5sumBeforeDownload $tmpMd5sumAfterDownload`

        if [ "$changeResult" == '' ]; then
            echo -e "$CYAN\nNone changes made in the local folder - All file still the same after de download$NC\n"
        else
            echo -e "$RED\n\nChanges made in local files:$NC"

            diffBeforeDownload=`diff -u $tmpMd5sumBeforeDownload $tmpMd5sumAfterDownload | grep -v "^--" | grep "^-" | awk '{print $2}'`
            diffAfterDownload=`diff -u $tmpMd5sumBeforeDownload $tmpMd5sumAfterDownload | grep -v "^++" | grep "^+" | awk '{print $2}'`

            for lineA in `echo $diffBeforeDownload`; do
                for lineB in `echo $diffAfterDownload`; do
                    if [ "$lineA" == "$lineB" ]; then
                        filesUpdate+=$lineA\|
                    fi
                done
            done

            if [ "$filesUpdate" != '' ]; then
                echo -e "$GREEN\nFile(s) updated:$NC"
                echo "$filesUpdate" | sed 's/|/\n/g'
            fi

            for lineA in `echo $diffBeforeDownload`; do
                diffLineDeleted=`echo $diffAfterDownload | grep $lineA`
                if [ "$diffLineDeleted" == '' ]; then
                    filesDeleted+=$lineA\|
                fi
            done

            if [ "$filesDeleted" != '' ]; then
                echo -e "$RED\nFile(s) deleted:$NC"
                echo "$filesDeleted" | sed 's/|/\n/g'
            fi

            for lineB in `echo $diffAfterDownload`; do
                diffLineNewFiles=`echo $diffBeforeDownload | grep $lineB`
                if [ "$diffLineNewFiles" == '' ]; then
                    filesNew+=$lineB\|
                fi
            done

            if [ "$filesNew" != '' ]; then
                echo -e "$CYAN\nNew file(s) downloaded:$NC"
                echo "$filesNew" | sed 's/|/\n/g'
            fi
        fi

        rm $tmpMd5sumBeforeDownload $tmpMd5sumAfterDownload
    fi

    cd $versionDownload/

    echo -en "$CYAN\nWant check the integrity of downloaded files with the server?$NC\n(y)es - (n)o $GREEN(press enter to no):$NC "
    read checkFiles

    if [ "$checkFiles" == 'y' ]; then
        echo -en "$CYAN\nChecking the integrity of the files.$NC Please wait..."
        if [ "$downloadSource" == 'y' ]; then
            checkFilesResult=`tail +13 CHECKSUMS.md5 | md5sum -c --quiet`
        else
            checkFilesResult=`tail +13 CHECKSUMS.md5 | grep -v "source/" | grep -v "patches/source/" | md5sum -c --quiet`
        fi

        if [ "$checkFilesResult" == '' ]; then
            echo -e "$CYAN\n\nFiles integrity:$GREEN Good$NC - files are equal to the server"
        else
            echo -e "$CYAN\n\nFiles integrity:$RED Bad$NC - files different from the server"
            echo -e "$RED$checkFilesResult$NC"
        fi
    fi

    cd ..

    echo -en "$CYAN\nWant create a ISO file from downloaded folder?$NC\n(y)es - (n)o $GREEN(press enter to no):$NC "
    read generateISO

    datePartName=`date +%Hh-%Mmin-%dday-%mmouth-%Yyear`
    isoFileName=$versionDownload\_date-$datePartName

    if [ "$generateISO" == 'y' ]; then
        olderIsoSlackware=`ls | grep "slackware.*iso"`

        if [ "$olderIsoSlackware" != '' ]; then
            echo -e "$CYAN\nOlder ISO file slackware found:$GREEN $olderIsoSlackware$NC"
            echo -en "$CYAN\nDelete these older ISO file(s) before continue?$NC\n(y)es - (n)o $GREEN(press enter to no):$NC "
            read deleteOlderIso

            if [ "$deleteOlderIso" == 'y' ]; then
                rm slackware*.iso
            fi
        fi

        echo -en "$CYAN\nCreating ISO file.$NC Please wait..."

        mkisofs -pad -r -J -quiet -o $isoFileName.iso $versionDownload/
        # -pad   Pad output to a multiple of 32k (default)
        # -r     Generate rationalized Rock Ridge directory information
        # -J     Generate Joliet directory information
        # -quiet Run quietly
        # -o     Set output file name

        echo -e "$CYAN\n\nThe file $GREEN\"$isoFileName.iso\"$CYAN was generated by the folder $GREEN$versionDownload/$NC\n"
    else
        echo -e "$CYAN\n\nExiting...$GREEN\n\nIf you want create a ISO file, use:$NC\nmkisofs -pad -r -J -o $isoFileName.iso $versionDownload/\n"
    fi
fi
