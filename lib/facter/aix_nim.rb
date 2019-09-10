#
#  FACT(S):     aix_nim
#
#  PURPOSE:     This custom fact returns a hash of information about the NIM
#		(client or server) configuration of the local machine.
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        May 15, 2019
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    (never)
#
#  MODIFICATION HISTORY:
#
#	(none)
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_nim) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Capture the installation status and version if it's there
    setcode do
        #  Define the hash we'll fill and return
        l_aixNimHash = {}

        #  Fill the only things we can really default
        l_aixNimHash['configured'] = false
        l_aixNimHash['is_master']  = false

        #  Read and minimally parse the /etc/niminfo file if it exists
        l_lines = Facter::Util::Resolution.exec('/bin/cat /etc/niminfo 2>/dev/null')

        #  Loop over the lines that were returned - regardless of client or server
        l_lines && l_lines.split("\n").each do |l_oneLine|
            #  Skip comments and blanks
            l_oneLine = l_oneLine.strip()
            next if l_oneLine =~ /^#/ or l_oneLine =~ /^$/

            #  Split and re-split regular lines
            l_nev   = l_oneLine.split(" ").slice(1..-1).join(' ')
            l_name  = l_nev.split("=")[0]
            l_value = l_nev.split("=")[1].delete('"').strip()

            #  Save everything we get in the name-->value hash
            l_aixNimHash[l_name] = l_value

            #  If this is the NIM_CONFIGURATION=xxx line, figure out if we're a master or not
            if l_name == 'NIM_CONFIGURATION'
                if l_value == 'master'
                    l_aixNimHash['is_master'] = true
                else
                    l_aixNimHash['is_master'] = false
                end
            end
 
            #  If we got here, NIM is at least minimally configured
            l_aixNimHash['configured'] = true
        end

        #  If we're a NIM master, gather hashes / lists of what we know
        if l_aixNimHash['is_master']
            #  Add the empty hashes / lists
            l_aixNimHash['clients']   = []
            l_aixNimHash['resources'] = {}

            #  Grab our list of NIM clients (normally just type = standalone these days)
            l_lines = Facter::Util::Resolution.exec('/usr/sbin/lsnim -t standalone 2>/dev/null')

            #  Loop over the lines that were returned
            l_lines && l_lines.split("\n").each do |l_oneLine|
                l_aixNimHash['clients'].push(l_oneLine.split(' ')[0])
            end

            #  Grab everything else from a summary 'lsnim' into a hash of lists
            l_lines = Facter::Util::Resolution.exec('/usr/sbin/lsnim 2>/dev/null')

            #  Loop over the lines that were returned
            l_lines && l_lines.split("\n").each do |l_oneLine|
                l_type = l_oneLine.split(' ')[2]
                next if l_type == 'master' or l_type == 'standalone'
                if ! l_aixNimHash['resources'][l_type]
                    l_aixNimHash['resources'][l_type] = []
                end
                l_aixNimHash['resources'][l_type].push(l_oneLine.split(' ')[0])
            end
        end

        #  Implicitly return the contents of the hash
        l_aixNimHash
    end
end
