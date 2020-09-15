prefixa=`echo $0 | awk -F 'azurerm_' '{print $2}' | awk -F '.sh' '{print $1}' `
tfp=`printf "azurerm_%s" $prefixa`
echo $ftp
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az network nsg list -g $rgsource -o json`
#comm=`printf "cat %s.json | jq '. | select (.[].id | contains(\"%s\"))'" $tfp $rgsource`
#echo $comm
#azr=`eval $comm`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rname=`echo $name | sed 's/\./-/g'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | sed 's/\./-/g' | tr -d '"'`

        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location" | tr -d '"'`
        srules=`echo $azr | jq ".[(${i})].securityRules"`

        prefix=`printf "%s__%s" $prefixa $rg`
        outfile=`printf "%s.%s__%s.tf" $tfp $rg $rname`
        echo $az2tfmess > $outfile
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $rname >> $outfile
        printf "\t name = \"%s\"  \n" "$name" >> $outfile
        printf "\t location = \"%s\"\n" $loc >> $outfile
        printf "\t resource_group_name = \"%s\"\n" $rgsource >> $outfile
        #
        # Security Rules
        #
        scount=`echo $srules | jq '. | length'`
        #echo $scount
        if [ "$scount" -gt "0" ]; then
        scount=`expr $scount - 1`
            for j in `seq 0 $scount`; do    
                      
            printf "\t security_rule { \n" >> $outfile
            srname=`echo $azr | jq ".[(${i})].securityRules[(${j})].name" | tr -d '"'`  
            echo "Security Rule $srname   $j of $scount"                     
            printf "\t\t name = \"%s\"  \n" "$srname" >> $outfile
            srdesc=`echo $azr | jq ".[(${i})].securityRules[(${j})].description"`                       
            if [ "$srdesc" != "null" ]; then
                printf "\t\t description = %s\n" "$srdesc" >> $outfile
            fi

            sraccess=`echo $azr | jq ".[(${i})].securityRules[(${j})].access" | tr -d '"'`                       
            printf "\t\t access = \"%s\"  \n" $sraccess >> $outfile
            srpri=`echo $azr | jq ".[(${i})].securityRules[(${j})].priority" | tr -d '"'` 
            printf "\t\t priority = \"%s\"  \n" $srpri >> $outfile
            srproto=`echo $azr | jq ".[(${i})].securityRules[(${j})].protocol"` 
            printf "\t\t protocol = %s  \n" $srproto >> $outfile
            srdir=`echo $azr | jq ".[(${i})].securityRules[(${j})].direction" | tr -d '"'` 
            printf "\t\t direction = \"%s\"  \n" $srdir >> $outfile

#source address block
            srsp=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourcePortRange"` 
            if [ "$srsp" != "null" ];then
            printf "\t\t source_port_range = %s  \n" "$srsp" >> $outfile
            fi
            srsps=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourcePortRanges"` 
            if [ "$srsps" != "[]" ];then
            printf "\t\t source_port_ranges = %s  \n" "$srsps" >> $outfile
            fi
            srsap=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourceAddressPrefix"` 
            if [ "$srsap" != "null" ];then
                printf "\t\t source_address_prefix = %s  \n" "$srsap" >> $outfile
            fi
            srsaps=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourceAddressPrefixes"` 
            if [ "$srsaps" != "[]" ];then
                printf "\t\t source_address_prefixes = %s  \n" "$srsaps" >> $outfile
            fi

# source asg's
            srsasgs=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourceApplicationSecurityGroups"` 
            kcount=`echo $srsasgs | jq '. | length'`
            if [ "$kcount" -gt "0" ]; then
                kcount=`expr $kcount - 1`
                for k in `seq 0 $kcount`; do
                    asgnam=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourceApplicationSecurityGroups[(${k})].id" | cut -d'/' -f9 | sed 's/\./-/g' | tr -d '"'`
                    asgrg=`echo $azr | jq ".[(${i})].securityRules[(${j})].sourceApplicationSecurityGroups[(${k})].id" | cut -d'/' -f5 | sed 's/\./-/g' | tr -d '"'`    
                    printf "\t\t source_application_security_group_ids = [\"\${azurerm_application_security_group.%s__%s.id}\"]\n" $asgrg $asgnam >> $outfile
                done
            fi

#destination address block
            
            srdp=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationPortRange"` 
            if [ "$srdp" != "null" ];then
                printf "\t\t destination_port_range = %s  \n" "$srdp" >> $outfile
            fi
            srdps=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationPortRanges"` 
            if [ "$srdps" != "[]" ];then
                printf "\t\t destination_port_ranges = %s \n" "$srdps" >> $outfile
            fi
            srdap=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationAddressPrefix"` 
            if [ "$srdap" != "null" ];then
            printf "\t\t destination_address_prefix = %s  \n" "$srdap" >> $outfile
            fi
            srdaps=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationAddressPrefixes"` 
            if [ "$srdaps" != "[]" ];then
            printf "\t\t destination_address_prefixes = %s  \n" "$srdaps" >> $outfile
            fi

# destination asg's
            srdasgs=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationApplicationSecurityGroups"` 
            kcount=`echo $srdasgs | jq '. | length'`
            if [ "$kcount" -gt "0" ]; then
                kcount=`expr $kcount - 1`
                for k in `seq 0 $kcount`; do
                    asgnam=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationApplicationSecurityGroups[(${k})].id" | cut -d'/' -f9 | sed 's/\./-/g' | tr -d '"'`
                    asgrg=`echo $azr | jq ".[(${i})].securityRules[(${j})].destinationApplicationSecurityGroups[(${k})].id" | cut -d'/' -f5 | sed 's/\./-/g' | tr -d '"'`    
                    printf "\t\t destination_application_security_group_ids = [\"\${azurerm_application_security_group.%s__%s.id}\"]\n" $asgrg $asgnam >> $outfile
                done
            fi
            printf "\t}\n" >> $outfile
            done
        fi

            #
            # New Tags block v2
            tags=`echo $azr | jq ".[(${i})].tags"`
            tt=`echo $tags | jq .`
            tcount=`echo $tags | jq '. | length'`
            if [ "$tcount" -gt "0" ]; then
                printf "\t tags = { \n" >> $outfile
                tt=`echo $tags | jq .`
                keys=`echo $tags | jq 'keys'`
                tcount=`expr $tcount - 1`
                for j in `seq 0 $tcount`; do
                    k1=`echo $keys | jq ".[(${j})]"`
                    re="[[:space:]]+"
                    if [[ $k1 =~ $re ]]; then
                        tval=`echo $tt | jq ."$k1"`
                        tkey=`echo $k1 | tr -d '"'`
                        printf "\t\t\"%s\" = %s \n" "$tkey" "$tval" >> $outfile
                    else
                        tval=`echo $tt | jq .$k1`
                        tkey=`echo $k1 | tr -d '"'`
                        printf "\t\t%s = %s \n" $tkey "$tval" >> $outfile
                    fi
                done
                printf "\t}\n" >> $outfile
            fi

        printf "}\n" >> $outfile
        cat $outfile
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $rname`
        echo $statecomm >> tf-staterm.sh
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $rname $id`
        echo $evalcomm >> tf-stateimp.sh
        eval $evalcomm
      
    done
fi
