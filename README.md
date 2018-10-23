# Azure-Tools
My utilities I wrote for managing Azure

## Update-IPRestriction  

After encountering a requirement to hide an Azure App Service behind an Application Gateway I wrote this script to run on schedule/trigger  
to update AAS's IP Restriction setting. This is necessary because as of 2018 Application Gateway still does not have a static Public IP and  
it can be reset whenever AG is started and stopped (and who the hell knows when else amirite Microsoft?). So this utility allows just for that.  
It is written with parameter parsing, debugging options and verbose mode, you can incorporate it into your own module if you want. Written to  
runon Powershell Core. Help and examples are provided in comment-based help in the scritp file.
