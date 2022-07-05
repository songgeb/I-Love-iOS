# FileSystem in iOS

An iOS Application sandbox directory

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_sandbox.png?raw=true)

- Bundle
	- app resources, such as images
	- signed during app installation, so readonly
	- not backed up by iTunes or iClound, but iTunes does perform an initial sync of any apps purchased from the App Store 
- Data Container
	- can store user, app data, writable
	- Documents
		- use to store user-generated content
		- user can access and share files 
		- backed up by iTunes, iCould
	- Documents/Inbox
		- access files that your app was asked to open by outside entities
		- can read, delete contens, can not edit
	- Library
		- not user data, app's data
		- Application Support, Caches subdirectories, can create custom directory
		- backed up by iTunes, iCloud
		- Caches, system may delete contents to free up disk space
	- tmp
		- for temp contents, may be purged
		- not backed up by iTunes, iCloud
- iCloud Container
	- almost readonly, can only edit by system framework

### 参考

- [File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html)
