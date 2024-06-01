# LMStudio-Client

![](/Docs/images/alpacas-prompt.gif)

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

This project isn't complete, and as of this writing the module isn't anywhere close to complete (_05/21/2024_). Please see my **development journal** below to follow my progress!

---

## Development Journal

### **Key:**

⬜️ **\- Feature/Improvement Incomplete**

**❌ - Cancelled/Removed**

**🚧 - Feature/Improvement In Progress**

**✅ - Feature/Improvement Complete**

**💡 - Idea**

🐛 **Bug**

---

### 05/31/2024

I incorporated **Invoke-LMSaveOrOpenUI** into **Import-LMConfig**. 'Twas a simple task.

I thought hard about the **Get-LMResponse** function. I'm going to have to move over a lot of code from **Start-LMChat**.

The parameters could get ugly, **💡** I may force the function to use the "**ManualChatSettings**" template, which I'll need to tweak and reshape for its repurposing. (_It was originally for **Start-LMChat**_)

**💡** In **Get-LMResponse**, it would be very useful to generate a Dialog File, and I'm now committed to putting it in. I will use the Dialog File tags field to tag dialogs generated in this way.

That's all for now!

---

### 05/30/2024

I put together **✅** **Edit-LMSystemPrompt**. It takes an **\-Add** or an **\-Remove** parameter. It's pretty simple, actually.

I've been slowing down a bit, but I'm still making myself work on this. I'm determined to "finish" it and make this journal public. It's one of the coolest things I've built in Powershell, and by far the most mature module I've ever written.

Perhaps tomorrow, I'll work on **Search-LMHistory**. If I want an easy day, I'll write **Get-LMResponse**.

**💡** With **Get-LMResponse**, I may integrate Dialog File generation. I'm not sure yet.

That's all for now.

---

### 05/28/2024

Back at it! I've cut out all of the non-config file input and validation in **Start-LMChat** and converted every variable to use the **Global:LMConfigVars**.

I've done some cursory validation, and it works without a hitch. It's also much shorter.

I've put the "Old" version of the function in the "_Scraps_" folder. It won't ever be completed, but it's there if people want the extensibility.

Here's some code I might need later:

`#region Moving this out of the way: -ChooseSystemPrompt triggers System Prompt selector (FUNCTION NOT BUILT YET)`

`If ($ChooseSystemPrompt.IsPresent){`

`$CurrentSysPrompt = $Global:LMStudioVars.ChatSettings.SystemPrompt`

`$Global:LMStudioVars.ChatSettings.SystemPrompt = Select-LMSystemPrompt -Pin`

`` If ($Global:LMStudioVars.ChatSettings.SystemPrompt -eq "Cancelled" -or `  ``

`` $null -eq $Global:LMStudioVars.ChatSettings.SystemPrompt -or `  ``

`$Global:LMStudioVars.ChatSettings.SystemPrompt.Length -eq 0){$Global:LMStudioVars.ChatSettings.SystemPrompt = "$CurrentSysPrompt"}`

`}`

`Else {$Global:LMStudioVars.ChatSettings.SystemPrompt = "Please be polite, concise and informative."}`

`#endregion`

**💡** I need to add a switch to **Start-LMChat**: **\-NoSave**. This will give the ability for a user to not record a chat if they don't want to.

**✅** I also included **$JobOutput.Dispose()** in the **Invoke-LMStream** function's **Get-Content -Wait** try/catch block. I wonder if some longer term instability I was seeing was because I wasn't properly closing my streamwriters. (_It could also be because I'm always running LMStudio locally when testing_).

---

### 05/27/2024

I had to do some design thinking today, and I realized that to prevent the options system from becoming a cluttered, complicated mess, I'm going to have to do away with the "extensibility" I've maintained.

The extensibility I'm speaking of is the use of certain functions without requiring the config file, or the configuration being loaded.

I've maintained certain parameters to ensure a user could use the program without depending on the config, if they wanted the freedom to use them in a way other than what I designed.

I don't like the idea of forcing people into doing the way I think is best, because what I think is best may not be the best use of the application. By removing that extensibility, I run the risk of forcing users to use the application in a way they don't like.

Or it might not matter at all. Users may really enjoy the "plug and play", relatively uninvolved way I've built it.

I'm hesitant, but I think I'm going to **✅** remove the extensibility. I have to make a decision and live with it, but there are other benefits to removing it:

- The code becomes shorter and more compact
- It eliminates a great deal of ways errors can be introduced
- It removes a lot of required validation
- It will simplify the featureset
- The simplified featureset will simplify the documentation (_which is very important to me_)

That's all for now, no coding today.

---

### 05/27/2024

Busy day yesterday, and took another break.

**✅** Instead of integrating markdown into the web client functions (**Invoke-LMBlob/Invoke-LMStream**), I built **Show-LMDialog** to handle Markdown/non-markdown output. It appears to be working pretty well.

🐛 The markdown integration isn't perfect. This time it's not my fault. **Show-Markdown** has some problems that I spent a few hours trying to circumvent but was unable to.

It has a problem with adding extra new-lines, which are not easily stripped out; and it has a problem removing some new-lines, which are not easily put back in.

I fought with a lot of different approaches to solving the problem, but I'm going to call it: for the time-being, it must remain imperfect.

**The list is getting shorter:**

**✅** Integrate **Invoke-LMSaveOrOpenUI** into **Import-LMConfig** (_when opening the file without specifying the path_)

⬜️Write how the **Start-LMChat** prompt is going to handle option (**:**) inputs. Maybe this should be an auxiliary function

💡 I can add parameters to **Show-LMHelp** to give details for each parameter

...

**These are functions I need to write:**

**✅** Write a **Modify-LMSystemPrompts** function (to add to/remove from the list)

⬜️ Write the **Search-LMHistory** function

⬜️ Write **Get-LMResponse** (single-response query, no console output).  
...

**And these are "admin" tasks:**

⬜️ Better prompts and questions for the greeting generator

**⬜️ Check my functions, and identify which have never been used by any other function**

⬜️ Separate out Public and Private functions (second-to-last thing to do)

⬜️ Build the **psd1** file out

⬜️ Documentation: this one is so important. I need to be very clear that this is built and designed to be easy to use, and is records-oriented: titling, tagging discussions, and searching for them, is what I built.

That's enough for now.

---

### 05/25/2024

I needed a break.

**✅** I gutted the validation and complexity in **New-LMConfig** in favor of a single-path approach: define -**BasePath** and everything else is created under this.

This gutting also enabled me to get rid of the **Set-LMHistoryFilePath** function, which was nothing more than a recursive directory creator.

#### **Follow-Up:**

I sorted out more bugs out today. Most notably, I fixed the index selection for **Update-LMHistoryFile**. In the event of a single matching entry, I was defaulting to **\[0\]**, which mapped to one of the "dummyvalues" in the History file.

**Markdown Plans:**

I did some thinking about how to implement Markdown. Doing it in-line will be impossible because of the way the async stream works: the output is directly to console, and the console pipeline can't be intercepted.

I did some experimenting, and the way **Show-Markdown** works is it converts string text into a series of meta-commands \[_edit:_ "_for serial text output emulation_") available to PS7 that is also displayed as string text. This means text converted to markdown only needs to be converted once.

The way I have to do this will be less than ideal, but better than the worst-case:

- Create a "**$MarkdownBuffer**" arraylist to store converted text
- For each message:
  - Add the latest message, converted to markdown, to the $MarkdownBuffer (with Timestamp and role)
  - Build the "console-consistent", markdown-converted output (as it displays in the console)
  - Clear the screen (**cls**)
  - Output the converted output
  - Present the next **You:** and **Read-Host**

It's not perfect. I really like how OpenAI converts it in-line, but I would need to redesign and improve how the HTTP client works, and that's a low priority.

**Follow-Up:**

**Select-LMSystemPrompt** is written, and does what it's supposed to. (_I've been doing a better job of testing features_). Next to do is to ⬜️ integrate it with **Start-LMChat.** I'll probably do that through an auxiliary function (⬜️ **Set-ChatSettings**?)

---

### 05/22/2024

**✅** Fixed problem with fragmentation in **Invoke-LMStream**: if the line fragmented twice, the second fragment wasn't caught.

**✅** I need to "go deep" on the **Do/Until** loop for **Invoke-LMStream**. There looks like a lot of room for optimization, and it's cludgy at present. I bet I can improve performance.

💡 I need to come up with a "Pacing" system to detect stuttering from a slow LLM response, and output console text so it's slower but smoother.

**✅** History File isn't being updated with **\-ResumeChat,** need to look into this.

**✅** Restructured **Invoke-LMStream** from a series of IF statements, to a switch. Tested with PS5/PS7, seems to work just fine.

#### **Follow-Up:**

I sorted a lot of little, meddling bugs out today.

I fixed problems with updating the History File, and problems with setting the "Opener" line in the Dialog Files and in the History File.

I improved **Repair-LMHistoryFile**'s functionality.

I fixed a problem with how I determined the default **MarkDown** property.

Plus everything above.

I forgot to add something to the list below: **✅** Export the System Prompt file in **New-LMConfig.**

That's all for now.

**Edit:** I forgot some things:

**❌**I need an empty "Return" in **Start-LMChat** to do nothing (erase current line, don't run). There's a way to erase the current written line, I should experiment with it to make it "transparent".

---

### 05/21/2024

**✅** Squashed a bug where I incorrectly terminated in a Default switch (PS5 doesn't assign '.Count' to most non-array objects). This was causing re-opened Dialog files to fail to save. Accommodates both 5/7 now.

**✅** Squashed another where the condition I set in the **:main** was causing the "Opener" property to be provisioned in the Dialog file, which leads (downstream) to it missing in the History file.

**✅** **\-** I made the System Prompts a template in **Get-LMTemplate,** which will be instantiated by **New-LMConfig**. This will solve the problem of how to guarantee the file and its location.

✅ - I made the "Open Cancelled" output gentler. No reason to throw an error over that.

Added **✅** **ChatSettings.SystemPrompt,** **✅** **ChatSettings.MarkDown** **✅** **ChatSettings.SavePrompt** everywhere:

- In the Config
- In the "ManualChatSettings" Template
- In **Get-LMGreeting**
- In **Start-LMChat** (both manual hashtable input and -UseConfig blocks)

The variables are now fully integrated. Now the fun part, building the functions they're intended for.

💡 I need to build a function that can serve as an intermediary for changing settings. What I could do is set the parameters to be whatever follows the ':' (:temp, ::maxdepth, etc) to specify the value: **:temp 0.5** or **ContextDepth 15**, etc.

- The trouble with this is it becomes difficult to accommodate the "manual" mode, though I did extend those settings via the manual setting hashtable

💡 I should probably be tracking the models and when they change. This could be done with **$Dialog.Info.Models** being an array/list containing two fields ("Model", "Timestamp") If the model changes, it gets updated there, and any "replay" will show the correct models for each prompt.

This is a bit much to bite off right now though, there's some time/order logic I'd need to implement, and that's much lower priority than putting the functions and aesthetic into place.  
**❌** In the **Set-LMSystemPrompt** function, I should permit a "manual" entry (as a hashtable, of course).

---

### 05/21/2024

**✅** Completed and tested **Repair-LMHistoryFile**, which effectively rebuilds the History File from scratch. Works pretty well.

This is a consolidated list of the work to do:

**🚧**Add the following variables to the Config File: \[**Moved**\]

**❌** Implement MarkDown into **Invoke-LMStream** and **Invoke-LMBlob**

**✅** Write **Get-LMSystemPrompt** (Involves more file-handling)

**✅** Integrate **Get-LMSystemPrompt**  into **Start-LMChat**, and possibly **New-LMConfig**.

**\[Moved\]** Separate out Public and Private functions (second-to-last thing to do)

**\[Moved\]** Integrate **Invoke-LMSaveOrOpenUI** where-ever files are being saved or opened (for name/path validation)

**\[Moved\]** Check my functions, and identify which have never been used by any other function.

**\[Moved\]** Get a start on how the **Start-LMChat** prompt is going to handle option (**:**) inputs. Maybe this should be an auxiliary function

**✅** Write a small console script that prompts for a "y/N" answer. (_Or a message box)_

**\[Moved\]** Go through my functions list and add/strike things off of the list.

**\[Moved\]** Better prompts and questions for the greeting generator.

💡 I can add parameters to **Show-LMHelp** to give details for each parameter

**\[Moved\]** Write **Get-LMResponse** (single-response query, no console output).

My work's cut out for me. If I can complete one or two of these a day, I'll be a pretty closed to ready to make it public.

Cheers!

---

### 05/20/2024

I Successfully integrated the **Import-LMDialogFile** function to make "picking up" the conversation work. History file writing and dialog retention is now working as it should.

**💡** I might add a kind of "break line" in the messages to indicate the model and date has changed, and that the conversation was picked back up.

**\[moved\]** In addition to the "**SystemPrompt**" variable, I want to add a **MarkDown** variable as well. This will be useful when it comes time to implement MarkDown with PS7.

---

### 05/19/2024

Put together the following functions:

**✅ Convert-LMDialogToHistoryEntry** : This intakes a dialog and generates an entry for the History File. It's a flat, simple function, with minimal validation.

**✅ Select-LMHistoryEntry :** This reads and parses the History file, and uses **Out-GridView** to present the contents for continuation of a previous dialog.

The **Select-LMHistoryEntry** function hints at the **✅** **Repair-LMHistoryFile** function, which still needs to be written. It's functionally simple, it'll use the **Convert-LMDialogToHistoryEntry** function to read every Dialog file and reassemble the History File.

**Today I need to:**

**✅** Integrate the two new functions into **Start-LMChat**

**✅** Sort out History File handling in **Start-LMChat**

**\[Moved\]** Integrate the **ChatInfo.SystemPrompt** field into the Configuration file

**Follow-Up:**

I spent quite a bit of time today (3-4 hours) working on the dialog file and history file interactions, and ironing out history file entries and trying to guarantee history accuracy for non-edge cases. I'm not perfectly confident, but I _think_ it's working as intended.

After doing some work on the **\-ResumeChat** support (And the **Select-LMHistoryEntry** integration), I was able to make the Dialog file read-in and presentation work as intended. It displays the **You:**/**AI:** prompts, replayed back as they were received.

💡 (I would like to modulate the replay speed (_in the same way that I do with the **Get-LMBlob** -**StreamSim** parameter, to give it some aesthetic consistency_).

**I now have the problem** that the Dialog file import types everything as fixed-length arrays. The consequence is that when the LLM response is received, the :main do loop can't append to the $Dialog.Messages sub-array.

It's causing a problem here:

![](/Docs/images/$Dialog.Messages.png)

Resulting in **this error:**

`MethodInvocationException:`  
`Line |`  
`2101 |          $Dialog.Messages.Add($UserMessage) | out-null`  
`|          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`  
`| Exception calling "Add" with "1" argument(s): "Collection was of a fixed size."`

**The solution**: I don't need to understand exactly how this error is manifesting (_getting into the **Convert-LMDialogToBody** function, and how it works)_ to solve this problem.

**✅ Import-LMDialogFile** will Spawn a dialog template, copy all of the **$Dialog** array data into the (_non-fixed size_) ArrayLists, and then return the re-provisioned and non-fixed object. This will make the **Convert-LMDialogToBody** function work properly.

Once that function works as intended (and it shouldn't be difficult to write), I can put that in place of **Line 1963:**

`try {$Dialog = Get-Content $DialogFilePath -ErrorAction Stop | ConvertFrom-Json -Depth 5 -ErrorAction Stop}`

`catch {throw $_.Exception.Message}`

And tah-duh! **\-ResumeChat** will be fully integrated into the **:main** loop algorithm. Then History File and Dialog file integration will be complete!

#### After I'm over that small hurdle, these are my next priorities:

**\[Moved\]** Add **$Global:LMStudioVars.ChatSettings.SystemPrompt** variable to make this value easilysettable/persistent.

**\[Moved\]** Write **Get-LMSystemPrompt** (Involves more file-handling, likely CSVs.

**\[Moved\]** Integrate **Get-LMSystemPrompt**  into **Start-LMChat**, and possibly **New-LMConfig**.

💡 Setting/changing the system prompt should be done via a function called **Set-LMSystemPrompt,** and adding/removing a prompt should be done via **Add-LMSystemPrompt.**

💡 Though I may consolidate all of the features into a single function, we'll see.

**\[Moved\]** Separate out Public and Private functions, though I might wait until I'm ready to hard-test it.

**❌** Read about how queuing works with the webserver, and update **Invoke-LMStream** and **Invoke-LMBlob** if they don't/won't work with it. (_It might work just fine now, we'll see._)

**\[Moved\]** Integrate **Invoke-LMSaveOrOpenUI** where-ever files are being saved or opened (for name/path validation)

💡 If the History File starts to become too big, I could figure out a way to break it out into files/folders.

**\[Moved\]** Check my functions, and identify which have never been used by any other function.

**\[Moved**\] Get a start on how the **Start-LMChat** prompt is going to handle option (**:**) inputs. I could outsource it to another function, we'll see.

---

### 05/18/2024

Today, I built the **Invoke-LMSaveOrOpenUI** function, which presents an Open/Save Windows dialog. This will _really_ help me cut down on validation code, in cases where the user provides no path or an invalid path.

- I need to integrate the function into every case where I open or save a CFG, INDEX, GREETING or DIALOG file
  - \[Moved\] **New-LMConfig**
  - \[Moved\] **Import-LMConfig**
  - \[Moved\] **Get-LMGreeting**
  - \[Moved\] **Start-LMChat**
- This will significantly simplify the History File selection in **Start-LMChat**.
- **\[Moved\]** I need to write a small console script that prompts for a "y/N" answer.
  - This will be useful in **Start-LMChat** and **New-Config**, where there are a lot of lines dedicated to repetitive y/N questions

**Follow-Up:**

I built a pretty functional "Save Prompt" system in **Start-LMChat**. I also added the **\-SkipSavePrompt** parameter, to bypass the whole thing:  I'll need to include a "**:s**" instruction in the **do/until** loop to give the user an opportunity to save the file during/after the dialog has begun.

**✅** I also fixed a problem with the **Invoke-LMSaveOrOpenUI** function's name generation: There was a **!Test-Path** instruction in there, and I had a good reason to put it there, but I can't remember why. So I pulled it out.

**✅** I decided to strip out the "**\-Lite**" parameter and all of its intricacies, in favor of a new **Get-LMResponse** function. This new function is a basic "_send a prompt, get an answer_" function. It's non-interactive, and built for use with coding (_like, some of my ambitions after I finish this project_).

**Follow-Up:**

Some improvements; started moving into the **Do/Until** loop to get a feel for what order I need to provision and save data.

I need another new function to keep things simple:

**✅** A Dialog => Body function:

- Intakes the contents of a Dialog object
- Evaluates the messages in the $Dialog.Messages Array
- References the $ContextDepth
- Builds the array, containing the leading \[system\] role statement, and the previous $ContextDepth number of \[user\] and \[assistant\] messages
- Returns a properly ordered $Body.messages array

**Follow-Up:**

I wrote the DIalog => Body function,(**Convert-LMDialogToBody**) and it's one of the most elegant little functions I've ever written. I had to fix a few things, but it works exactly in the way I need it to work, and helps declutter **Start-LMChat**.

**Priorities:**

**\[moved\]** Add **$Global:LMStudioVars.ChatSettings.SystemPrompt** variable to make this value easilysettable/persistent.

**✅** Chase down **Update-HistoryFile**, **Import-HistoryFile,** work out how to save the key Dialog information to the History File

---

### 05/17/2024

Today, I built the **Invoke-LMBlob** function, which isn't complete or polished but should take **✅** maybe 5-10 more minutes to make functional and error-sensitive.

I also established that **.Net Framework 4.5** is the minimum I require for this code to work, due to the use of async methods in the C# code.

Out of curiosity, I used ChatGPT to generate a non-obsolete version of the C# class I'm using for the asynchronous HTTP session. It works great in PS7, standalone, except that it crashed my console. When I run it standalone, it runs okay, but error handling seems to be broken. **❌ Shelving this for now,** let me get everything else working first.

**Out-Gridview** has the curious feature of allowing a user to double-click an entry, which sends a value to a variable. This is **super** helpful for file management.

I will use the **Out-Gridview** functionality to make it easy to:

**✅**  Resume a previous conversation (using the History File)

**\[Moved\]**  Select a System Prompt (from a statically defined list of system prompts, exported from LM Studio).

I'm also not happy with my **Get-LMGreeting** prompt generator. Functionally, it's perfect; but **\[Moved\]**  I need better prompts and questions.

**\[Moved\]** Also need to go through my functions list and add/strike things off of the list.

#### **Follow-Up:**

**✅** I decided to write the path to the config file to $Global:LMConfigFile. This is done by **Import-LMConfig** and **New-LMConfig**. At this time, the only place I'm using the variable is in **Set-LMVariableOptions** (**✅**  soon to be **Set-LMOptions**) . Not sure if there's a use for it anywhere else.

**✅** I changed **$UseLoadedConfig** to **$UseConfig**. Documentation regarding parameters will cover this more ambiguous parameter name.

**✅**  Shell Functions **Set-LMSystemPrompt** and **Select-LMHistoryFile** were created to use **Out-GridView** as a file selection mechanism.

**\[Moved\]** I should probably add **$Global:LMStudioVars.ChatSettings.SystemPrompt** variable to make this value settable/persistent.

I've begun shaping the parameters for **Start-LMChat**, which will be rewritten from a copy of **Get-LMGreeting**.

- I've added a **\-ResumeChat** parameter, exclusive to the **\-UseConfig** parameter.
  - The reason I made this choice is because making **Start-LMChat** capable of picking up the History File makes the Config pointless.
  - **💡** A future accommodation (_via perhaps a typical Windows browse form_) might be made.
- **❌** I've added a -**Lite** parameter to send single, unrecorded prompt to the server, where you receive a single response back.
  - **❌** Greetings will be turned off with this feature, and cannot be turned on.
  - I would like to create a function that only responds (or does anything) if **$Global:LMStudioVars** is provisioned
    - This function would pass the **Start-LMChat** function a set of parameters, pulled from **Global:LMChatLite**
    - Command would look like **lc -q "**_Please give me 5 facts about America\*\*"\*\*_
  - **❌** I need to add a **LiteParams** template in the **Get-LMTemplate** function.

**Follow-Up:**

I made significant progress on **Start-LMChat**. I'm working through the **begin {}** block, pulling in variables and data. I have quite a bit of work to do. I think the next steps will be handling the condition of **(1)** a new History file, **(2)** continuing a dialog, and **(3)** no history file.

Once I have the history file management set up, it'll be time to enter the **Do/Until** loop, and all that fun (Send/receive responses, append responses to history dialog, write out history dialog; Build "Help" and "Options", set and manage quit options).

I also **✅** incorporated **Invoke-LMBlob** into **Get-LMGreeting.**

---

### 05/16/2024

I spent a great deal of time last night implementing parameter validation. This is not yet complete.

**Start-LMGreeting** (**✅** _soon to be renamed **Get-LMGreeting**_) works great:

![](/Docs/images/get-lmgreeting.gif)

**✅** The only code remaining for **Start-LMGreeting** is to write the received information out to the **hello.greeting** file in the folder.

Some additional things I'd like to accomplish today/tomorrow:

- **✅** Incorporate the following fields into the Config File:
  - $Global:LMStudioVars. Endpoints = @{}
    - .Endpoints.ModelURI = \[computed from ServerInfo Server, Port information\]
    - .Endpoints.CompletionURI = \[computed from ServerInfo Server, Port information\]
  - $Global:LMStudioVars.ChatSettings.Greeting = \[boolean\]

#### **Follow-Up:**

I parameterized a few more functions. It didn't get me back a lot of lines, but ti's cleaner now. **❌** **\[Set-LMGlobalVariables\]** and a few others still need parameterizing.

#### **Follow-Up:**

I got a lot of things done today: created all of the Config entries I could ever need; I deleted the superfluous **Set-LMGlobalVariables** and **Initialize-LMVarStore** functions and instead incorporated their utility directly into the (_now renamed_) **Import-LMConfig** and **New-LMConfig** functions.

**Import-LMConfig** will be supplemented by **Set-LMOption \[-Commit\],** which serves to change settings in **Global:LMStudioVars**, as well as **✅** Save the state of **$Global:LMStudioVars** _as-is_.

**\[Moved\]** Mark-down might be a neat thing to experiment with, particularly for the **New-Config** prompts as well as verbose check results.

**Get-LMGreeting** works perfectly, and **✅**I need to finish incorporating it into the **Start-LMChat** function.

---

### 05/15/2024

I worked diligently through the input typing problems I had all throughout **Start-LMGreeting**, and fixed the **temperature, max_depth** and **stream** type validations. (_It's important because Powershell's JSON conversions are particular about type, and meet formatting standards._) I then set to task to implement more advanced parameters, where every non-switch parameter is validated. This allowed me to cut out 150 lines of cluttering code.

I'm happy with the flow, the aesthetic and the functionality of it, and **Start-LMGreeting** is a neat toy and a good proof on concept. (_Name may change to **Get-LMGreeting**_).

I've moved on to doing the same for **New-ConfigFile**, and shortly after I'll do **Import-ConfigFile**. **New-ConfigFile** won't benefit as much because I need the prompts, but I also want the input parameters. **Import-ConfigFile** will benefit a little.

I'm on the fence about **$CompletionURI** and **$ModelURI**. I think it would be convenient and "clean" in a small way. The temptation to reduce a whole bunch of duplicate API endpoint paths into a couple variables and parameter names is strong, but I have more important problems to solve at the moment.

**✅** Oh yeah, I restored the fragmentation functionality to the **Invoke-LMStream** function. It turns out to be a problem with models that seem to "struggle" with assembling and returning the words. It wasn't my code, it wasn't the computer, it's the model and web server software.

(_Something they could do with LM Studio to improve the web server would be to moderate the stream output speed to be slightly slower than the average of all received characters in a burst. Sounds easy but it's hard to do, but it would make the output slower but less "jittery"_).

(_Alternatively, I could do it myself, from the front-end_).

**✅** I also forgot to implement the "**Greeting**" property in the **$Global:LMVars**. Whoops, I'll do that tomorrow.

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

- **✅** I use "_$null -ne $\_ -or $\_.Length -gt 0_" a LOT. It works, but it's not elegant. I will work toward moving to this, instead (where it makes sense):

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
**✅**  **New-LMHistoryFile** does nothing but save an arbitrary file, it's a pointless function. I just have to do:

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

**\[Moved\]** I can separate out Public and Private functions, and provide a Module Parameter to [expose all functions (for an advanced user)](https://stackoverflow.com/questions/36897511/powershell-module-pass-a-parameter-while-importing-module)

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

**\[Moved\]** Markdown compatibility: If (1) Client is PS7, (2) "**Show-Markdown**" is an available cmdlet, and (3) a "**\-Markdown**" (or similar) parameter is provided, I can use the **Show-Markdown** cmdlet to beautify the output

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

**\[Moved\]** Update Show-LMHelp to include changing the Title/Tags, Change the context message count, Save (without qutting)

**\[Moved\]** I can add parameters to Show-LMHelp to give details for each parameter  
✅ Make an official list of functions, and their purpose  
**✅**Update the Client to use the complete functions I have (should shorten the code substantially)  
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
✅ Dialogs themselves will be stored as either random or sequentially named files, with the following columns:

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

_**\[edit\]**_ The asynchronicity of **Invoke-LMStream** is probably one of the most functional and well-performing instances of using a job that I've ever built.

Most jobs are treated as "dump a bunch of tasks off at once, and then collect the results", to maximize multithreading in a script.

In this case, I'm maximizing the utility of a single additional thread: I'm running a background task that is receiving JSON web responses directly from the web server, which is writing those to a text file on disk.

In the foreground, I'm reading that text file whenever I can (**Get-Content -Tail**) and outputting a text stream to console.

From the parent process (the main thread), the Powershell console, I'm retrieving the data stored in the job's return buffer (**Receive-Job**) in a loop. The console output from the job is returned as an array of strings.

Every instance in the loop, I'm reading, interpreting and acting in various ways against each line in the returned array: throwing errors, converting from JSON to objects, writing out to the console, returning objects.

**And they say  Powershell isn't programming** ¯\\\_(ツ)\_/¯

_**\[/edit\]**_

- **Invoke-LMStream** uses "old" C# Web Client integrations; ⬜️ need to track down what version of the .NET Framework (2.0?) is required for the C# code to run.

---

### 05/06/2024

✅ Found a way to simulate asynchronous HTTP stream, built a working "streaming" response system; converted over to Powershell 7 standards; began functionalizing the code.  
**✅ Left off:** Moving all inputs for $HistoryFile over to $Global:LMStudioServer.HistoryFilepath, with checks for the path's validity

---

### 04/27/2024 - 05/05/2024

Built prototype, built greeting system, built history file system, began functionalizing.

_**\[edit\]**_ There's not a lot here from when I started this journal. I didn't realize how important the journal would be for keeping track of required and desired features.

The first week was spent building some lightweight proofs of concept. In this time, I worked out the HTTP body format and strict typing requirements, the base code for sending and receiving responses, and built a functional Question/Response flow using "Blob" (_all at once_) output.

I was very excited about the working client/server functionality, but unhappy with having to wait for a complete response. So I began to look into how I might "stream" the output to console in an aesthetically similar way as LLM service providers do (OpenAI, Groq, etc)., A great deal of time was spent successfully building such a system.

_**\[/edit\]**_
