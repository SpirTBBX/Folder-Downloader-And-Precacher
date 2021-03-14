#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1.0"

char configFile[256];
char filesConfig[256];

char fileExtensions[][] = 
{
	"mdl", "phy", "vtx", "vvd", "pcf",
	"vmt", "vtf", "png", "svg",
	"mp3", "wav", "m4a",
	"bsp", "nav"
};

/*char soundExtensions[][] =
{
	"mp3", "wav", "m4a",
};

char modelExtensions[][] =
{
	"mdl", "phy", "vtx", "vvd",
};

char materialsExtensions[][] =
{
	"vmt", "vtf", "png", "svg",
};

char mapExtensions[][] =
{
	"bsp", "nav"
};*/

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

ConVar g_supportType, g_download, g_precache;
bool folderSupport = false;
bool downloadEnabled = false;
bool precacheEnabled = false;

public Plugin myinfo = 
{
	name = "[SpirT] Folder Downloader and Precacher",
	author = PLUGIN_AUTHOR,
	description = "Adds a folder to the downloads table. All files will be precached",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	BuildPath(Path_SM, configFile, sizeof(configFile), "configs/SpirT/Folder-Downloader-Precacher/folders.txt");
	BuildPath(Path_SM, filesConfig, sizeof(filesConfig), "configs/SpirT/Folder-Downloader-Precacher/files.txt");
	
	if(!FileExists(configFile) || !FileExists(filesConfig))
	{
		SetFailState("[SpirT - Downloader & Precacher] Could not a config file. Make sure that both '%s' and '%s' exist.", configFile, filesConfig);
	}
	else
	{
		PrintToServer("[SpirT - Downloader & Precacher] Config files loaded successfully.");
	}
	
	RegServerCmd("sm_dl_reload", Command_Refresh);
	g_supportType = CreateConVar("spirt_dl_support_type", "1", "(1 - enables | 0 - disabled) 1 - Just specify folders at folders.txt and it would add files automatically. 0 - Specify all files manually at files.txt");
	g_download = CreateConVar("spirt_dl_download", "1", "(1 - enables | 0 - disabled) 1 - Enables adding files to the downloads table. 0 - Disables adding files to the downloads table");
	g_precache = CreateConVar("spirt_dl_precache", "1", "(1 - enables | 0 - disabled) 1 - Enables file precaching. 0 - Disables file precaching");
	AutoExecConfig(true, "folder-downloader-precacher", "SpirT");
}

public void OnConfigsExecuted()
{
	if(GetConVarInt(g_supportType) == 1)
	{
		folderSupport = true;
	}
	else
	{
		folderSupport = false;
	}
	
	if(GetConVarInt(g_download) == 1)
	{
		downloadEnabled = true;
	}
	else
	{
		downloadEnabled = false;
	}
	
	if(GetConVarInt(g_precache) == 1)
	{
		precacheEnabled = true;
	}
	else
	{
		precacheEnabled = false;
	}
	
	PrintToServer("Precaching: %d      Downloading: %d           SupportType: %d", precacheEnabled, downloadEnabled, folderSupport);
	CheckConfig();
}

public Action Command_Refresh(int args)
{
	if(folderSupport)
	{
		LoadFolderFile(configFile);
	}
	else
	{
		LoadFilesFile(filesConfig);
	}
}

void CheckConfig()
{
	if(folderSupport)
	{
		LoadFolderFile(configFile);
	}
	else
	{
		LoadFilesFile(filesConfig);
	}
}



void LoadFilesFile(const char[] file)
{
	File handle = OpenFile(file, "r+");
	char filePath[256];
	while(ReadFileLine(handle, filePath, sizeof(filePath)))
	{
		TrimString(filePath);
		if(!FileExists(filePath))
		{
			PrintToServer("[SpirT - Downloader & Precacher] File '%s' does not exist.", filePath);
			continue;
		}
		
		PrintToServer("[SpirT - Downloader & Precacher] File '%s' is being added to the downloads tabled and precached", filePath);
		SetupFile(filePath);
	}
	
	CloseHandle(handle);
	return;
}

void LoadFolderFile(const char[] file)
{
	File handle = OpenFile(file, "r+");
	char folderPath[256];
	while(ReadFileLine(handle, folderPath, sizeof(folderPath)))
	{
		TrimString(folderPath);
		if(!DirExists(folderPath))
		{
			PrintToServer("[SpirT - Downloader & Precacher] Folder '%s' does not exist.", folderPath);
			continue;
		}
		
		PrintToServer("[SpirT - Downloader & Precacher] Folder '%s' is being added to the downloads tabled and precached", folderPath);
		SetupFolder(folderPath);
	}
	
	CloseHandle(handle);
	return;
}

void SetupFolder(const char[] folder)
{
	if(DirExists(folder))
	{
		DirectoryListing dir = OpenDirectory(folder);
		char buffer[PLATFORM_MAX_PATH];
		FileType fileType = FileType_Unknown;
		
		while(ReadDirEntry(dir, buffer, sizeof(buffer), fileType))
		{
			if (!StrEqual(buffer, "") && !StrEqual(buffer, ".") && !StrEqual(buffer, ".."))
			{
				Format(buffer, sizeof(buffer), "%s/%s", folder, buffer);
				if(fileType == FileType_File)
				{
					if(FileExists(buffer, true))
					{
						SetupFile(buffer);
					}
				}
				else if(fileType == FileType_Directory)
				{
					SetupFolder(buffer);
				}
			}
		}
		
		CloseHandle(dir);
	}
	else
	{
		PrintToServer("[SpirT - Downloader & Precacher] Folder '%s' not valid", folder);
	}
}

void SetupFile(const char[] file)
{
	char extension[PLATFORM_MAX_PATH];
	GetFileExtension(file, extension, sizeof(extension));
	
	for (int i = 0; i < sizeof(fileExtensions[]); i++)
	{
		if(StrEqual(extension, "mdl") || StrEqual(extension, "phy") || StrEqual(extension, "vtx") || StrEqual(extension, "vvd"))
		{
			if(downloadEnabled)
			{
				AddFileToDownloadsTable(file);
				PrintToServer("[SpirT - Downloader & Precacher] Model added to downloads table: %s", file);
			}
			if(precacheEnabled)
			{
				PrecacheModel(file, true);
				PrintToServer("[SpirT - Downloader & Precacher] Model precached: %s", file);
			}
		}
		else if(StrEqual(extension, "vmt") || StrEqual(extension, "vtf") || StrEqual(extension, "png") || StrEqual(extension, "svg"))
		{
			if(downloadEnabled)
			{
				AddFileToDownloadsTable(file);
				PrintToServer("[SpirT - Downloader & Precacher] Material added to downloads table: %s", file);
			}
			if(precacheEnabled)
			{
				PrecacheDecal(file, true);
				PrintToServer("[SpirT - Downloader & Precacher] Material precached: %s", file);
			}
		}
		else if(StrEqual(extension, "mp3") || StrEqual(extension, "wav") || StrEqual(extension, "m4a"))
		{
			if(downloadEnabled)
			{
				AddFileToDownloadsTable(file);
				PrintToServer("[SpirT - Downloader & Precacher] Sound added to downloads table: %s", file);
			}
			if(precacheEnabled)
			{
				PrecacheSound(file, true);
				PrintToServer("[SpirT - Downloader & Precacher] Sound precached: %s", file);
			}
		}
		else if(StrEqual(extension, "bsp") || StrEqual(extension, "nav"))
		{
			if(downloadEnabled)
			{
				AddFileToDownloadsTable(file);
				PrintToServer("[SpirT - Downloader & Precacher] Map added to downloads table: %s", file);
			}
		}
		else if(StrEqual(extension, "pcf"))
		{
			if(downloadEnabled)
			{
				AddFileToDownloadsTable(file);
				PrintToServer("[SpirT - Downloader & Precacher] Particle added to downloads table: %s", file);
			}
			if(precacheEnabled)
			{
				PrecacheGeneric(file, true);
				PrintToServer("[SpirT - Downloader & Precacher] Particle precached: %s", file);
			}
		}
	}
}

bool GetFileExtension(const char[] filepath, char[] filetype, int length)
{
	int loc = FindCharInString(filepath, '.', true);
	if(loc == -1)
	{
		filetype[0] = '\0';
		return false;
	}
	strcopy(filetype, length, filepath[loc + 1]);
	return true;
}