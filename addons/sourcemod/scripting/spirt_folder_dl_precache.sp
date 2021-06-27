#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1.2"

#include <sourcemod>
#include <sdktools>

char folderFile[PLATFORM_MAX_PATH];
char filesFile[PLATFORM_MAX_PATH];

ConVar g_downloads, g_precache, g_looktype;
bool downloads, precache, looktype;

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
	BuildPath(Path_SM, folderFile, sizeof(folderFile), "configs/SpirT/Folder-Downloader-Precacher/folders.txt");
	BuildPath(Path_SM, filesFile, sizeof(filesFile), "configs/SpirT/Folder-Downloader-Precacher/files.txt");
	
	if (!FileExists(folderFile) || !FileExists(filesFile))
	{
		SetFailState("Could not find required file '%s'", folderFile);
		LogError("[SpirT - DL PRECACHE] Could not find required file '%s'", folderFile);
	}
	
	g_looktype = CreateConVar("spirt_dl_support_type", "1", "(1 - enables | 0 - disabled) 1 - Just specify folders at folders.txt and it would add files automatically. 0 - Specify all files manually at files.txt");
	g_downloads = CreateConVar("spirt_dl_download", "1", "(1 - enables | 0 - disabled) 1 - Enables adding files to the downloads table. 0 - Disables adding files to the downloads table");
	g_precache = CreateConVar("spirt_dl_precache", "1", "(1 - enables | 0 - disabled) 1 - Enables file precaching. 0 - Disables file precaching");
	AutoExecConfig(true, "spirt.dl");
}

public void OnConfigsExecuted()
{
	downloads = GetConVarBool(g_downloads);
	precache = GetConVarBool(g_precache);
	looktype = GetConVarBool(g_looktype);
	
	if (!downloads && !precache)
	{
		SetFailState("Both downloads and precache are disabled. Plugin will quit");
		LogError("[SpirT - DL PRECACHE] Both downloads and precache are disabled. Plugin will quit");
	}
	else
	{
		if (looktype)
		{
			FolderLoop();
		}
		else
		{
			FileLoop();
		}
	}
}

void FolderLoop()
{
	File file = OpenFile(folderFile, "r");
	char fileLine[128];
	while (ReadFileLine(file, fileLine, sizeof(fileLine)))
	{
		TrimString(fileLine);
		LookPathType(fileLine);
	}
	
	CloseHandle(file);
}

void FileLoop()
{
	File file = OpenFile(filesFile, "r");
	char fileLine[128];
	while (ReadFileLine(file, fileLine, sizeof(fileLine)))
	{
		TrimString(fileLine);
		if (FileExists(fileLine))
		{
			PrepareFile(fileLine);
		}
	}
	
	CloseHandle(file);
}

void LookPathType(const char[] path)
{
	DirectoryListing dir = OpenDirectory(path);
	char buffer[PLATFORM_MAX_PATH];
	FileType fileType = FileType_Unknown;
	
	if (dir != null)
	{
		while (ReadDirEntry(dir, buffer, sizeof(buffer), fileType))
		{
			if (!StrEqual(buffer, ".") && !StrEqual(buffer, "..") && !StrEqual(buffer, ""))
			{
				char newPath[PLATFORM_MAX_PATH];
				Format(newPath, sizeof(newPath), "%s/%s", path, buffer);
				if (fileType == FileType_File)
				{
					PrepareFile(newPath);
				}
				else if (fileType == FileType_Directory)
				{
					LookPathType(newPath);
				}
			}
		}
		
		CloseHandle(dir);
	}
}

void PrepareFile(const char[] path)
{
	char fileExtension[PLATFORM_MAX_PATH];
	GetFileExtension(path, fileExtension, sizeof(fileExtension));
	if (StrEqual(fileExtension, "mdl") || StrEqual(fileExtension, "phy") || StrEqual(fileExtension, "vtx") || StrEqual(fileExtension, "vvd"))
	{
		CheckDownload(path);
		CheckPrecache(path, "model");
	}
	else if (StrEqual(fileExtension, "vmt") || StrEqual(fileExtension, "vtf") || StrEqual(fileExtension, "png") || StrEqual(fileExtension, "svg"))
	{
		CheckDownload(path);
		CheckPrecache(path, "materials");
	}
	else if (StrEqual(fileExtension, "mp3") || StrEqual(fileExtension, "wav") || StrEqual(fileExtension, "m4a"))
	{
		CheckDownload(path);
		CheckPrecache(path, "sound");
	}
	else if (StrEqual(fileExtension, "bsp") || StrEqual(fileExtension, "nav") || StrEqual(fileExtension, "ani"))
	{
		CheckDownload(path);
	}
	else if (StrEqual(fileExtension, "pcf"))
	{
		CheckDownload(path);
		CheckPrecache(path, "generic");
	}
}

bool GetFileExtension(const char[] filepath, char[] filetype, int length)
{
	int loc = FindCharInString(filepath, '.', true);
	if (loc == -1)
	{
		filetype[0] = '\0';
		return false;
	}
	strcopy(filetype, length, filepath[loc + 1]);
	return true;
}

void CheckDownload(const char[] path)
{
	if (downloads)
	{
		AddFileToDownloadsTable(path);
		PrintToServer("[SpirT - DL PRECACHE] File '%s' was added to the downloads table", path);
	}
}

void CheckPrecache(const char[] file, const char[] precacheType)
{
	if (precache)
	{
		if (StrEqual(precacheType, "model"))
		{
			PrecacheModel(file, true);
			PrintToServer("[SpirT - DL PRECACHE] File '%s' was added to models precache table", file);
		}
		else if (StrEqual(precacheType, "materials"))
		{
			PrecacheDecal(file, true);
			PrintToServer("[SpirT - DL PRECACHE] File '%s' was added to materials/decal precache table", file);
		}
		else if (StrEqual(precacheType, "sound"))
		{
			PrecacheSound(file, true);
			PrintToServer("[SpirT - DL PRECACHE] File '%s' was added to sound precache table", file);
		}
		else if (StrEqual(precacheType, "generic"))
		{
			PrecacheGeneric(file, true);
			PrintToServer("[SpirT - DL PRECACHE] File '%s' was added to generic precache table", file);
		}
	}
} 