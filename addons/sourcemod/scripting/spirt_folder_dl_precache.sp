#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.0.1"

char configFile[256];

char fileExtensions[][] = 
{
	"mdl", "phy", "vtx", "vvd",
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
	
	if(!FileExists(configFile))
	{
		SetFailState("[SpirT - Downloader & Precacher] Could not load config file '%s'", configFile);
	}
	else
	{
		PrintToServer("[SpirT - Downloader & Precacher] Config file loaded successfully.");
	}
	
	RegServerCmd("sm_dl_reload", Command_Refresh);
}

public Action Command_Refresh(int args)
{
	LoadConfigFile(configFile);
}

public void OnMapStart()
{
	LoadConfigFile(configFile);
}

void LoadConfigFile(const char[] file)
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
		
		SetupFolder(folderPath);
		PrintToServer("[SpirT - Downloader & Precacher] Folder '%s' is being added to the downloads tabled and precached", folderPath);
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
			AddFileToDownloadsTable(file);
			PrecacheModel(file, true);
			PrintToServer("[SpirT - Downloader & Precacher] Model added to downloads table and precached: %s", file);
		}
		else if(StrEqual(extension, "vmt") || StrEqual(extension, "vtf") || StrEqual(extension, "png") || StrEqual(extension, "svg"))
		{
			AddFileToDownloadsTable(file);
			PrecacheDecal(file, true);
			PrintToServer("[SpirT - Downloader & Precacher] Material added to downloads table and precached: %s", file);
		}
		else if(StrEqual(extension, "mp3") || StrEqual(extension, "wav") || StrEqual(extension, "m4a"))
		{
			AddFileToDownloadsTable(file);
			PrecacheSound(file, true);
			PrintToServer("[SpirT - Downloader & Precacher] Sound added to downloads table and precached: %s", file);
		}
		else if(StrEqual(extension, "bsp") || StrEqual(extension, "nav"))
		{
			AddFileToDownloadsTable(file);
			PrintToServer("[SpirT - Downloader & Precacher] Material added to downloads table: %s", file);
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