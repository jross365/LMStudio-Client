# LMStudio-Client

This project is to develop a full-featured, capable PowerShell 5 and PowerShell 7 LMStudio client.

This client interfaces with the LMStudio Web Server, allowing a user to use LMStudio from a remote workstation.

**Features**

- Response streaming: LLM output is displayed as it is generated
- Records and saves LLM chat dialogs
  - Built-in file management, indexing and search capabilities
- Persistent configuration management:
  - Settings are preserved in a configuration file
  - Settings can be modified and saved easily

This module is being built and improved upon, and features are implemented as they're discovered.

Please see my **development journal** below to follow my progress!

---

## Development Journal

### **Key:**

⬜️ **\- Feature/Improvement Incomplete**

**🚧 - Feature/Improvement In Progress**

**✅ - Feature/Improvement Complete**

---

### 05/16/2024

I spent a great deal of time last night implementing parameter validations. This is not yet complete.

**New-LMGreeting** (⬜️ _soon to be **Get-LMGreeting**_) works great:

![](/Docs/images/get-lmgreeting.gif)

---

### 05/15/2024

I worked diligently through the input typing problems I had all throughout **Start-LMGreeting**, and fixed the **temperature, max_depth** and **stream** type validations. (_It's important because Powershell's JSON conversions are particular about type, and meet formatting standards._) I then set to task to implement more advanced parameters, where every non-switch parameter is validated. This allowed me to cut out 150 lines of cluttering code.

I'm happy with the flow, the aesthetic and the functionality of it, and **Start-LMGreeting** is a neat toy and a good proof on concept. (_Name may change to **Get-LMGreeting**_).

I've moved on to doing the same for **New-ConfigFile**, and shortly after I'll do **Import-ConfigFile**. **New-ConfigFile** won't benefit as much because I need the prompts, but I also want the input parameters. **Import-ConfigFile** will benefit a little.

I'm on the fence about **$CompletionURI** and **$ModelURI**. I think it would be convenient and "clean" in a small way. The temptation to reduce a whole bunch of duplicate API endpoint paths into a couple variables and parameter names is strong, but I have more important problems to solve at the moment.

**✅** Oh yeah, I restored the fragmentation rfunctionality to the **Invoke-LMStream** function. It turns out to be a problem with models that seem to "struggle" with assembling and returning the words. It wasn't my code, it wasn't the computer, it's the model and web server software.

(_Something they could do with LM Studio to improve the web server would be to moderate the stream output speed to be slightly slower than the average of all received characters in a burst. Sounds easy but it's hard to do, but it would make the output slower but less "jittery"_).

(_Alternatively, I could do it myself, from the front-end_).

⬜️ I also forgot to implement the "**Greeting**" property in the **$Global:LMVars**. Whoops, I'll do that tomorrow.

---

### 05/14/2024

New problems with **Invoke-LMStream**: The job is no longer reliably returning full/whole lines on its own. I need to figure out a way to figure out if the last line in **$JobOutput** is incomplete, and if so, carry it to the next line.

#### **Follow-Up:**

What I think was happening is degraded server performance from my system being up so long. Rebooting made the "fragmentation" issue disappear.

What I think might have been happening is the LLM was being "slow" due to GPU overclock settings being applied (seen this before). Get-Content -Wait was reading the file in between lagtimes in each line-stream, causing the code to return fragmented lines.

Will resume working on **Start-LMGreeting** tomorrow.

#### **Follow-Up:**

**✅** Wrote **Set-LMOptions** to create a way to dynamically adjust variables (like _max_tokens, temperature, context_). Wrote it in a way that it doesn't depend on a fixed list of keys.

Finished updating **Import-LMHistoryFile**.

**A few script-wide improvements to do:**

- **🚧** I use "_$null -ne $\_ -or $\_.Length -gt 0_" a LOT. It works, but it's not elegant. I will work toward moving to this, instead (where it makes sense):

```
Parameter ValidateScript: [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]

If (!($PSBoundParameters.ContainsKey('PARAMETERNAME'))){}
```

- **✅** **"Temperature", "Max_Tokens" and "ContextDepth"** should be stored, if not in the History File, then in the dialog file. I haven't gotten to writing dialog handling yet, so it's something to do while building is early.

#### **Follow-Up:**

**✅** Fixed **Import-LMConfigFile**, added enhancements to **Import-ConfigFile**.

**✅**Fixed **Initialize-LMVarStore, Set-LMGlobalVariables, Confirm-LMGlobalVariables**.

**✅** Pointed all **$Global:LMHistoryVars.HistoryFilePath** entries to **$Global:LMHistoryVars.FilePaths.HistoryFilePath**.

---

### 05/13/2024

In moving over functions to use the **New-LMTemplate** (_which is not done, HistoryFile template has a LOT of hooks_), with a sense of doom I realized I absolutely have to get all of the client settings I need into the config management system. If I don't, it'll be a headache to fix later.

I have much of the Config File (object) formatting done. **✅** **Confirm-LMGlobalVariables** needs to be rewritten.

**✅** I need to rewrite **Import-LMConfigFile** to accommodate the new config JSON structure., specifically Lines 261 - 269.

---

### 05/12/2024

**✅** Finished the **New-LMTemplate** function; added **temperature,max_tokens,stream,ContextDepth** to Config file and to global settings incorporation.

**TO DO TOMORROW:**  
**✅** Move functions over to the New-LMTemplate  
**✅** Remove the old standalone template functions  
**✅** Evaluate whether I can remove functions I've labeled as such

#### **Follow-Up:**

Had another thought:

**✅** I need to convert all "New-LMHistoryFile" calls to the new Template function.  
**🚧**  **New-LMHistoryFile** does nothing but save an arbitrary file, it's a pointless function. I just have to do:

```
[Get a new history entry template] | Convertto-Json -Depth 3 | out-file $somefilepath
```

I need to do this URGENTLY, because it's one of those small modifications that can create hassle downstream.

Also, getting rid of an extra function gets rid of the ability and utility to omit "dummy values". For the history file, when I need a template I'll simply re-fill in the dummy fields.

This also simplifies the way History Files are created and appended to.  
   (It also suggests that, since the data is flat, I should be using a CSV!)

#### **Follow-Up:**

Doing documentation, clean-up and identifying missing functions today. Might break the functions out into Public/Private.

**Some Ideas:**

⬜️ I can separate out Public and Private functions, and provide a Module Parameter to [expose all functions (for an advanced user)](https://stackoverflow.com/questions/36897511/powershell-module-pass-a-parameter-while-importing-module)

✅ I can combine all of my object (template) creations into a single function (simplification)

- ✅ Should include the HTTP $Body in this

⬜️ I can add parameters to Show-LMHelp to give details for each parameter

✅ I can build out the "Greeting" functionality as a standalone function

✅ Would move a lot of the Start-LMStudioClient code out of the main body

✅ Create a standalone "greeting" client

✅ Need to incorporate other values into the $Global:LMStudioVars and Config File:

- Subtree "Settings" (To be changed manually):
  - Temperature = 0.7 (default)
  - Context = 10 (default)
  - Stream = $True (default)
  - StreamCacheFile = $env:userprofile\\Documents\\lmstream.cache (default)

⬜️ Markdown compatibility: If (1) Client is PS7, (2) "**Show-Markdown**" is an available cmdlet, and (3) a "**\-Markdown**" (or similar) parameter is provided, I can use the **Show-Markdown** cmdlet to beautify the output

- The way this would work with "Stream" mode:
  - that a copy of the output would would retained (as per usual:  **$Output = Invoke-LMStream**  
           \* the screen will be cleared:  **Clear-Screen**  
           \* The output would be passed:  **Show-Markdown -InputObject $Output**

---

### 05/11/2024

Finished **Import-LMConfigFile**, which wasn't an easy step: input validation and caution is important here, because cleaning up mistakes is a hassle when files and folders are created all over the place.

Also touched up a few other functions. I added two new fields to the history file: "**Title**", and "**Tags**". It'll make human consumption easier, and make the data easier to search.

I have many of the important pieces together now. I REALLY want to build a functioning client, but it's very important I have the data and file structures right from the start. It's much easier to do right the first time than to have to fix.

**\[FileInfo\]** is a really neat class. It's very useful for getting name and paath information from a hypothetical file or folder.

**Next up:**

⬜️ Update Show-LMHelp to include changing the Title/Tags, Change the context message count, Save (without qutting)  
✅ Make an official list of functions, and their purpose  
⬜️ Update the Client to use the complete functions I have (should shorten the code substantially)  
Review this, and likely simplify/replace it (Client):\`

✅ Need to check if this is still valid:

```
If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$Hist...
```

---

### 05/10/2024

Finished **Import-LMConfigFile**, which required parameterizing a whole bunch of functions and fixing various checks/validations. New-LMConfigFile comes next.  
✅ **Create-LMConfigFile** will have the following parameters:

- Server
- Port
- HistoryFile
- Defaults to $Env:UserProfile\\Documents\\LMStudio-Client
- SkipServerValidation (Doesn't check Server/Port)
- NewHistory
- If History file is detected:
  - moves File and its folder to a ".bkp" folder
  - creates a new file/Folder
  - Notifies user

✅ **Create-LMConfigFile** will not have mandatory parameters

- If any parameters are missing, they'll be prompted for

---

### 05/09/2024

Started building out **Import-LMConfigFile**; ✅ this required parameterizing **Get-LMModel**. ✅ I need to parameterize **Import-LMHistoryFile** so I can test it during the **Import-LMConfigFile** process.

I'll keep working from top to bottom to build out the functions this module needs. NOTE: I also should build a **Start-LMStudioLiteClient** to get a working prototype to play with.

#### **Follow-Up:**

Re-ordered functions according to the dependencies and processes. Built shells for many (but not all) of the functions I'll need to write and incorporate.

Have decided to "fragment" Dialogs from the History File:

✅ History File will keep an index of Dialog files and some information about them (Date, opening line, model, Dialog (array))  
⬜️ Dialogs themselves will be stored as either random or sequentially named files, with the following columns:

- Index, prompt type \[system, assistant, user\], body (statement/response)
- Dialog files will be colocated in a folder next to the history file
- Dialog files will have a "header" in the JSON that contains same information as is assigned to the History File index

✅ Have decided to "fragment" Greetings from the History File:

- No greeting information kept in the History File
- Greeting file will be called "greetings.diasht" and will be kept in the above folder
- Greeting will keep a "flat" format - Will likely use CSV
- Will contain simple columns: Index, Date, Model, Prompt Type, Statement/response

✅ I have also built some of the functionality for a "master" configuration file, which will serve the following purpose:

- Required input will be consumed/validated (server, port, history file):
- Config file created
- Config file will be imported:
  - Global Variable Store $Global:LMStudioVars will be provisioned and populated (w/ config file info)
  - Values will all be validated (server, port, history file)
  - History file legibility will be checked (History files won't be validated)
  - From this system, startup will be much easier
- input server info once, create history file, and everything is saved
- ⬜️ When module is imported, everything that was predefined will be used to provision the required information (server, port, history file)

A lot has gotten done. There is still a lot to do. I think the first thing I'll do is create a "Lite" client to use in the meantime. Perhaps build in the "SaveAs" for use

---

### 05/09/2024

Re-ordered functions according to the dependencies and processes. Built shells for many (but not all) of the functions I'll need to write and incorporate.

---

### 05/07/2024 - 05/08/2024

✅ These two days were spent building and testing the asynchronous, job-based streaming response function (**Invoke-LMStream**). Much trial and error, but it's fully functional.

**Invoke-LMStream** uses "old" C# Web Client integrations; ⬜️ need to track down what version of the .NET Framework (2.0?) is required for the C# code to run.

---

### 05/06/2024

✅ Found a way to simulate asynchronous HTTP stream, built a working "streaming" response system; converted over to Powershell 7 standards; began functionalizing the code.  
**✅ Left off:** Moving all inputs for $HistoryFile over to $Global:LMStudioServer.HistoryFilepath, with checks for the path's validity

---

### 04/27/2024 - 05/05/2024

Built prototype, built greeting system, built history file system, began functionalizing.
