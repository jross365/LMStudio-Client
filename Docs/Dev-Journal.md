## Development Journal

### **Key:**

**❌ - Cancelled/Removed**  🚧 **- Feature/Improvement In Progress**

⬜️ **- Feature/Improvement Incomplete**  ✅ **- Feature/Improvement Complete**

💡 **- Idea  🐛 - Bug**

---
### 09/07/2024
I have completed the preliminary Powershell help. It's somewhat sparse, but it's all there and usable.

✅ I have settled on keeping all the functions in a single **psm1** file. I've deleted the *Public* and *Private* folders, and the empty files in those directories.

✅ I have also expanded the module import to include arguments:

**Exports all (public and private) functions**
```
Import-Module LMStudio-Client -ArgumentList "ExportAll"
```

**Auto-loads the config on import**
```
Import-Module LMStudio-Client -ArgumentList "Auto"
```

The documentation has been updated to include how to use the ```-ArgumentList``` parameter with **Import-Module**.

I also updated other documentation: I moved the Dialog/History File information into **history-and-dialog.md**. This decluttered the **Slow-Start-Guide.md** file.

I needed a break. After jumping back into this project today, I was able to complete a whole lot of other tasks.

That's all for now.

---
### 08/27/2024
🐛 ```:condepth ##**``` wasn't working, but I fixed it. Probably worthy of a minor version increment, but it's not really necessary.

Completed a bit more of the Powershell Help. I'm getting toward the end!

---
### 08/25/2024
Additional progress made on the Powershell help.

🐛 I discovered a problem where the defined settings (max_tokens, temperature, etc) as defined in $BodySettings of **Start-LMChat**, was being updated *administratively* but not actually being applied.

This is because the **$BodySettings** hashtable was initially defined in the top of the *process {}* block, but not in the **:main** loop. It was set once, and it could be changed in the Config and updated in the Dialog Files, but the settings weren't actually being applied after the initial application.

I discovered this issue while evaluating the parameters for **Convert-LMDialogToBody**, which is where I left off on the Powershell help.

Unrelated, I'm putting this here (from the README.md) for posterity:

**07/07/2024** ~~The current version of the code does **not** work with Powershell 5. I will attempt to resolve this issue, and I'm not sure when it was first introduced.~~ This issue is caused by the use of the **clean {}** block in Powershell, which I learned was only introduced in 7.3.

I've commented out the **clean {}** block (for now).

That's all for now.

---
### 08/24/2024
Additional progress made on the Powershell help. Finished help for **Invoke-LMStream**.

I've been busy, but trying to finish this part of the work before I go through the "nice-to-haves" and begin implementing them.

---
### 08/18/2024
Additional progress made on the Powershell help. Finished help for **Search-LMChatDialog**.

---
### 08/17/2024
I've made some very good progress with the documentation, and I think I can call it "*complete enough*" to put it on hold and work on some other things.

I had some help with the greetings generator for **Get-LMGreeting**, and I fixed a 🐛problem stemming from missing some commas in an array.

After I commit these updates, I'll probably begin working on the Powershell Help.

**Follow-Up:**

I renamed *Update-LMHistoryFile* to **Update-LMHistoryEntry**. It makes more sense.

Completed several Powershell Help headers.

---
### 08/08/2024
I'm making additional solid progress on the User Guide. I have a few more instructionals to put into the **history-and-dialog.md** file, and that will knock out another whole section to write about.

⬜️ I need to strip out all manual parameters which provide inputs to the History File.

⬜️ In my code, I throw an error that states to **Run Import-ConfigFile** (or something to that effect). I need to correct this error.

That's all for now.

---
### 08/07/2024
I haven't committed any updates in a bit over a week, but I have been chipping away at the documentation. The User Guide (called the *slow start guide* right now) is coming along pretty well, and I think it will be more valuable than the cmdlet options.

A few improvements are on my mind:

💡 I should add a **RootFolderPath** key/value pair to the **Global:LMConfigVars.FilePaths** Config Branch. This would make moving a user profile *much* easier, requiring only one key change.
If I go this route, *every single instance* where I reference one of the **FilePaths** Leafs will need to be updated as a concatenation of **RootFolderPath** and the relative path of the file.

⬜️ **Get-LMDialogContent** is unwritten. It'll more or less be this:
```
Show-LMDialog -DialogMessages  (Import-LMDialogFile -FilePath $(Select-LMHistoryEntry)).Messages
```
*which leads to the next improvement...*
 
 ⬜️**Show-LMDialog** should provide two options:
 
 - Display in console (*-AsConsoleText*): provides markdown options

 - Default (*No parameter*): return as a string object

 For now, I'm going to put that **Show-LMDialog** chain of function inputs as the way to display text. But I very much need to write **Get-LMDialogContent** as a wrapper for this.
 The reason I didn't finish the function is because I was burned out a bit; but I've had enough time away from coding now to pick up where I left off.

 I'll keep chipping away at the documentation. That's all for now.


---
### 07/31/2024
🐛 :markdown in **Start-LMChat** wasn't working. I need to go through the **Set-LMCLIOption** settings and make sure the substring matching is correct for each setting. (Oops)

Until I fix the the substring parameters in **Set-LMCLIOption**, options won't always work correctly. I'll fix this sooner rather than later.

**Follow-Up:**
Quite a few updates to the documentation. I've written the **Start-LMChat** user guide. I also fixed some broken links. It's coming together quite nicely.

I also ✅ fixed the **Start-LMChat** options being utterly broken.
The mistake I'd made was that when I shifted from the fixed-length (5) options names to the variable-length names, I forgot to update the *$UserInput.SubString()* statements used to parse the input.

I have adjusted the SubString Start and Count values to accommodate each commands' lengths (":markdown" being 9, for example). This solves the problem.

I also ✅ Added a **Module Version** and **Last Update** fields to the README.md. I need to be more vigilant about updating the minor code version in the PSD1 file.

I'm enjoying writing the documentation, and I expect to get more done soon. More later!

---
### 07/30/2024
The last few days were spent working on structuring and creating a coherent format for the documentation.

Not a lot of actual technical writing has been done yet, but I'm now at a point where I can buckle down and get it done.

I also need to write the actual Powershell **Get-Help** documentation, which is drier but much easier to write.

I'm also considering scrapping the separation of functions into respective **private** and **public** folders. I don't know, yet.


---
### 07/28/2024
Working on documentation. It's tough; there's a lot to document.

I also need to do two things:

⬜️ Update/adapt **Show-LMDialog** to return the contents as an object/array instead of **Write-Host** output
⬜️ Write **Get-LMDialogContent** as a wrapper for selecting, importing and then showing a Dialog File


---
### 07/23/2024
I've scrapped the previous plan. I'm putting the Help headers into the placeholder .ps1 files in the folders.

When the help header is complete, I'm putting this comment above the function:

```
# Help Complete
```

I think I'll alternate between writing the GitHub Repo documentation (which will be more valuable) and writing the Powershell Module documentationl

That's all for now.


---
### 07/22/2024
I integrated **$global:LMStudioVars.FilePaths.DialogFilePath** into **Show-LMSettings**. Which was the whole reason I decided to keep the latest Dialog file in the Config in the first place.
*(Edit:) What I meant by this is that the Show-LMSettings function previously required the Dialog File path be provided, which was cludgy and unrefined. This is what motivated me to integrate DialogFilePath.*

I have also created the Private/Public folder breakout for the file-individuated functions structure. The empty files have been placed as placeholders until I am ready to begin.

My current plan is to follow this process:

1. Copy the function into its named file.
2. Write the **Get-Help** documentation for the function in the new file.
3. Remove the function from the **LMStudio-Client.psm1** file.

This process will ensure that the documentation for each function is written, without any being skipped.

That's all for now.

---
### 07/21/2024
I integrated **$global:LMStudioVars.FilePaths.DialogFilePath** into **Start-LMChat**.

Under every circumstance:
- If the key doesn't exist (*you have an old version of the config file, missing the key*), it is created (as "new") in $global:LMStudioVars.FilePaths (not saved to the Config File)

**Start-LMChat**'s new code works like this:

- **Start-LMChat -Resume** first looks at the *DialogFilePath* key

- If the path is *not* valid (via **Test-Path**), it sets a flag to trigger a Dialog file selection (from History)
- If the path is valid, it sets **$DialogFilePath** to the value in **$global:LMStudioVars.FilePaths.DialogFilePath**
- The value is saved to the Config file via **Set-LMConfigOptions -Commit**

- **Start-LMChat -Resume -FromSelection** works exactly like **Start-LMChat -Resume** used to work: it goes straight to Dialog file selection.
- When a Dialog file is selected, it is saved to $Global:LMStudioVars.FilePaths.DialogFilePath
- The value is saved to the Config file via **Set-LMConfigOptions -Commit**

There's a recurring theme where I anticipate changes/improvements/updates will be far more time and effort-consuming than they end up being. I also find myself thanking my past self for doing things in particular ways.

I'm looking into methods to separate **Get-Help** output from a psm1 file, I would like to avoid making it 8000 lines long, being 50% in-module documentation.

That's it for now.


---
### 07/18/2024
Before doing anything else, I split up ✅ **Edit-LMSystemPrompt** into the ✅ **Add-** and ✅ **Remove-** functions that they should have been from the very beginning.

I've fixed:

✅ :settitle
✅ :addtags
✅ :remtags

The problem was that I wasn't re-importing the Dialog File after setting the title/tags on the file. The resulting incongruence is that the options would set them in the file, but in the next instance of the loop they'd be overwritten to the old values in the "living" $Dialog instance.

I added a flag to re-import the Dialog File, which those options now trigger.

✅:maxtoks now works correctly

✅ I updated **Start-LMChat -ResumeChat** to **Start-LMChat -Resume**

I scrolled back to three weeks of the journal to find problems I knew about but hadn't fixed, and I couldn't find any. So I suppose I can at least make this module import-able, before splitting it up into individual files.

✅ I also created a **psd1** file, so this 

---
### 07/17/2024
Title and tags parameters are **not** working in **Start-LMChat**. I have to fix this tomorrow (the date this is under).

- I think I fixed **Set-LMTags -Action Add**, we'll see.

- **Set-LMTitle** works as intended, I need to review how **:settitle** works.


### 07/16/2024
I had a decent idea:
✅ I should store the Dialog File path in **$global:LMStudioVars:FilePaths**.

Here's how I should do it:
❌ I should use the History File to determine the last opened Dialog File
- I would trigger this through an external function (**Get-LatestDialogFile**)
- It would exclusively be triggered by **Start-LMChat**, 

✅ This would allow me to do the following:
- Reassign **-ResumeChat** to automatically open the previously stored Dialog File
- **-ResumeChat -Pick** (*or something similarly named*) should be used to initiate opening the History File
- Allow me to include the Dialog File in **Show-LMSettings** without having to provide the path

This idea came to me while working on the output for **Show-LMSettings**.

I think this idea *should* be implemented, but it's **not my first priority**.

✅ I need to split up **Edit-LMSystemPrompt** into two separate functions (*The usability of the function is atrocious*):

- ✅ **Add-LMSystemPrompt**
- ✅ **Remove-LMSystemPrompt**

✅ I need to rename the **-ResumeChat** parameter to **-Resume**

Documentation really should be priority right now, though.
The code is usable. It's going to be improved over time, and things smoothed out and simplified. But it's genuinely functional.

Chipping away at a few other bug fixes and improvements. Moved my journal into this file, off of the README.md.

That's all for now.

---
### 07/13/2024
I've ✅ added **:clear** to the options, which was easy: I just had to rediscover this function I wrote:

```Show-LMDialog -DialogMessages $Dialog.Messages -AsMarkdown```

✅ The **:help** page on GitHub is also complete. It could use some polish, maybe some categories.

✅ **:title** and **:settitle** are also in place. **:title** shows the title, and **:settitle** sets it.

---
### 07/12/2024
✅🐛 Setting **:maxtoks** doesn't work. I need to figure out and fix it, sooner than later.

I figured this out while writing documentation for the **Start-LMChat** Options.

✅ I need to create a good way to display settings (including things like title, tags, dialog file, etc) so that a user can copy them out. The old fashioned message box doesn't allow for copying anything out of the prompt.
*<edit>* I did this via updates with **Show-LMSettings**.

I'm working through the [**Start-LMChat-Options.md**](./Docs/Start-LMChat-Options.md) documentation, which is now what **Show-LMHelp** opens when you provide the **:help** input.

That's all for now.

---
### 07/11/2024
Instead of storing the timestamp of the last entry, I wrote in storing the last index (**$LastEntryIndex**). I also wrote in the Dialog File reversion and History File reversion. This little detour turned out to not be too difficult to complete.

It ✅ needs testing (*tested 07/14*), but it's simple enough that there's very little to go wrong.

I also substituted this in for **:help**:

```start-process "https://github.com/jross365/LMStudio-Client/blob/main/Docs/Start-LMChat-Options.md"```

I'll begin working on Start-LMChat-Options.md, shortly. That's all for tonight.

---
### 07/10/2024
A quick note for me:

❌ **Line 3643** is an unnecessary If !(Test-Path (History File)) code block.

* For **-ResumeChat**, I need ✅ to track the date/timestamp of the last entry in the dialog.

The reason is because if the user enables **PrivacyMode**, we need to restore the dialog file to its previous state.

After I've stored the date of the last entry, ✅ I need to remove all newer entries from the dialog content, restore the modified date, and update the history file. *Sheeeeew.* 

💡 This set of requirements for **PrivacyMode** originated from my writing an Options instructional, to be launched by the command **:help**.

I realized that if Privacy Mode were enabled in a *-ResumeChat* -started session, I didn't have code to clean up the Dialog File. That's a problem for a feature with the word "privacy" in it.

That's all for now.

---
### 07/09/2024
Taking a break today.

 I need to write a ❌ **Get-LMDialogContent** (or similarly named) function to read and display the content of any given dialog file, as it would be displayed in a chat prompt. Maybe include some parameters like *-Markdown* and *-ResultSetSize*, etc.

The function would be intended for both saving/manipulating, and for displaying.

This will help me with the **:clear** option I need to write, and I think it would supplement some of the code that support the Markdown option. It would also make it easier to read the chat contents of files.

💡 I also am considering removing every input parameter and supporting code that allows a user to specify a manual history file. It's marginal in its utility relative to the complexity overhead and opportunities for bugs and errors.

That's all for now.

---
### 07/08/2024
Finished moving option selections over from a series of **If (){}** statements to the **switch {}** statement. Preliminary testing shows it works great.

~~The next step is to move options over to keyword **:opt**.~~ Decided not to do it this way; it's "power-user friendly" but very "regular-user unfriendly".

**Follow-Up:**

Substantial improvements; added **:addtags** and **:remtags**, and did a thorough test. There is a new function called **Set-LMTags**, which enabled me to move all the tag management logic out of **Start-LMChat**.

**Set-LMTags** not only updates the tags in the Dialog File, but provides an **-UpdateHistoryFile** switch which also updates the tags listed in the History File for the Dialog File.

Here are some other enhancements I have planned:

✅ ":clear" option to clear out options output and refresh the console's continuity/appearance

✅ ":title" option to set the title on the dialog file and corresponding history (*may do this with a ✅ **Set-LMTitle** function, similar to **Set-LMTags**)

✅ Need to show history/dialog file paths with an option ~~(":files"?) ~~ **:show** (*shows settings*)

✅ Rename options in **Set-LMCLIOptions** to the new names

❌ ~~Update **Show-LMHelp** to reflect the new names~~ 07/16/2024: This is obsolete, with the establishment of the *Start-LMChat-Options.md* file

💡 Would like to set the "**You**" and "**AI**" prompts to whatever a user wants them to be, via **$Global:LMStudioVars.ChatSettings.Username** and **$Global:LMStudioVars.ChatSettings.AsstName** values.

The last idea would require updates to the Config File Template, which is easy (*everything hinges off of the template*). Regenerating a new Config File is also easy and painless; however, I should include an **Upgrade-LMConfigFile** function (or something similar) to "port over" settings for older Config Files over to the latest/greatest.

💡 ✅ Instead of an archaic message box via **Get-LMHelp**, I should launch a browser to navigate to the GitHub documentation via something like this:

```
Start-Process "Https://github.com/jross365/LMStudio-Client/Docs/Start-LMChat-Options.md"
```

I'll chip away at the above items. That's all for now.

**Follow-Up:**

I've knocked out several things on the list that I planned to do to do. I'm considering switching over to GitHub-based documentation for the help, if anything so the console session isn't monopolized by a UI message box.

That's all for now.

---
### 07/07/2024
Implementing **-AsObject** was simpler than I expected. It works as intended.

I also removed **-WriteProgress**, as the searches complete very quickly, even with numerous search terms. I don't see any benefit to adding steps for processing, given how quick it is.

💡 It would be sensible for **Search-LMChatDialog** to *only* return an object, and for the object to be converted to human-friendly text via a dedicated function (**Convert-LMSearchResults**?). I'm not putting time into making this happen just yet, but it's here for future reference.

✅ I added a **-Confirm** parameter to **Remove-LMHistoryEntry**. It's a [boolean] that defaults to $True.

I've started looking into what it would take to provide multi-length strings for setting options, such as

* :maxtokens instead of :mtok
* :contextdepth instead of :cond
* :setprompt instead of :selp
* :newprompt instead of :newp
* :addtag instead of :atag
* :deltag instead of :dtag
* :greet instead of :gret
* :stream instead of :strm
* :saveprompt instead of :save
* :showmd instead of :mark

etcetera. Piggy-backing this improvement, I would also prefer to move the tag-adding and tag-removing code out of the **:main** loop of **Start-LMChat**. I need to think through how I might do this (to be determined.)

Oh yeah, PS5 support's been broken for a while now. Not sure what broke it or when, but I'll try to fix it.

That's all for now.

**Follow-Up**

I had to add a feature to **Remove-LMHistoryEntry** so I could intelligently trigger *Privacy Mode*. Now, if you specify **-DialogFilePath**, the function will key off of the provided path to delete the entry (and the file, if specified).
The entire purpose of adding this in was to support the **:priv** command (which I'm in the process of moving into a *switch* statement.)

✅ I need to finish moving over the **:<option>** options over to the new *switch* statement. I left off at this line [3662]:

```
{$OptionKey -ieq ':tags'}{} #07/07: IN THE PROCESS OF MOVING THESE OVER TO THE NEW SWITCH
```

---
### 07/06/2024
I fixed the **ContextDepth** issue this morning, it was exactly what I thought it was: I'd forgotten to move the **$ContextDepth** variable over to **$Global:LMStudioVars.ChatSettings.ContextDepth** in several places.

I also discovered that 🐛 **Remove-LMHistoryEntry -DeleteDialogFiles** wasn't deleting dialog files. After correcting my code, I used this procedure to recreate the History File, and then re-deleted the files I wanted:

```
# Reconstructs the History File from the files in the Dialog Folder:
Repair-LMHistoryFile -FilePath $global:LMStudioVars.FilePaths.HistoryFilePath

# Presents a UI to select History File entries for deletion, along with corresponding files:
Remove-LMHistoryEntry -BulkRemoval -DeleteDialogFiles
```
I've written this entire module to be usable in this way. I will write documentation, I promise.

It occurred to me that I should provide a way to return the results of **Search-LMDialog**, and so I've added an **-AsObject** parameter. The most expedient way to build this feature is to return an object with something along the following structure:

```
$Object.SearchSettings                  #A record of the input parameters
$Object.SearchResults                   #A hashtable to store the search results
$Object.SearchResults.Index             # An array which contains the file information and corresponding key name for each file which contains matches
$Object.SearchResults.$DialogFileName   #A hashtable key named for the Dialog File, which contains the $SearchMatches output
```
This design choice leads to a bit more work, but it adds to the utility of the tool: it allows me (or anyone else) to use the function as a tool for other purposes besides re-reading.

That's all for now.

---
### 07/05/2024
Messages are now being appended to $Results more or less in the way I want them.

✅ I need to append the dialog file information to the Results so the user knows where the text was found.

**Follow-Up:**
I put a lot of work into **Search-LMDialog** today. I fixed a bunch of bugs, set up the output format, and added a **MATCH** tag (*with the matched terms*) to be displayed in the output.

Capitalizing is also working as intended.

I've run the function as a function and it does match and return many instances, but it doesn't always catch every instance. This tells me something's not working right with selecting and pruning with the deduplication step.

✅ **ContextDepth** is no longer showing up in Dialog Files. This is probably easy to fix, and I need to figure it out.

I may play around with the display format for the **MATCH** tag in the text, but the hardest part of this function is working.

✅ The next thing to do will be to run the code against *every* accumulated Dialog File I have, and review the output to confirm it's working as intended.

❌ After that, I need to implement the **-WriteProgress** output.

**Follow-Up:**
✅ I made this code block and blocks more sensible:

```
  :msgloop Foreach ($Message in $MatchingMessages){
            ...}
```

Instead of trying to figure out and add the Selected Messages (matched and prior/after context messages), I should only add the relevant information (**MatchedEntry, DialogIndex and MatchPhrase**) to the existing matching message object, which will be appended to **SelectedMessages**.

I will append any auxiliary message indexes to **$AuxilliaryIndexes**, and sort/unique the list.

Then, I will remove any indexes listed in **$AuxiliaryIndexes** that are also in the **$MatchingMessages** array.

The remaining messages at indexes in **$AuxiliaryIndexes** will be appended to **$SelectedMessages**.

Then sort the thing by **DialogIndex**, and I no longer need to worry about deduplication.

---
### 07/04/2024
Solving the challenge of exact pattern matching and capitalizing matches turned out not to be too troublesome, and I think I have it together.

I'm now working on presenting the results in a text format that's human friendly. I've constructed the file's header (which lists the parameters used for the search). For the actual matches, I plan on grouping them according to contiguous indexes (1-4 grouped, 7-10 grouped, ) separated by dashes.

Unrelated to **Search-LMDialog**, but 💡 I think it would be cool if the "You:" and "AI:" prompts could be customized with labels, stored in the LMConfig variables.

I'm committed to ✅ changing the options (**:gret**, **:help**) to allow for variable length strings (allowing for **:greet**, **:help**, etc.). This will make the options/settings more user friendly.

I need to finish a draft version of **Search-LMDialog** first, and then I can update/improve the options.

---
### 07/01/2024
I worked out deduplication and ordering. Now I need to conquer the problem of capitalizing the matched letters. I may need to redesign my matching system and capitulate to building regex expressions.

I was able to rid of one superfluous **Else {}** statement.

I also found a simple (*and now, obvious*) way to handle type preservation when using **Select-Object** and **Sort-Object**: explicitly specify the type [system.collections.arraylist]. Duh.

That's all for now.

---
### 06/30/2024
I'm working on sorting, filtering and deduplicating match and match-adjacent Dialog messages. It's not terribly complicated, but I do have some Invoke-Expression trickery in there, and it's better to look at the code than to try to explain it in this instance.

More later.

**Follow-Up:**

Squashed a 🐛 where I was incorrectly counting the maximum index for the range of indexes needed, per the **-PriorContext** and **-AfterContext** parameters.

I also eliminated an unnecessary switch, and simplified how the code manages the prior/after messages (which evaluates whether the selected message is a *user* or *assistant* message).

And, I added a hash table to keep track of what messages have been added to the **$SelectedMessages** arraylist. I *could* write this to eliminate deduplication, but for the time being it's a performance *improvement* (not a *solution*.)

💡 **After I get through everything else**, I may want to revisit this optimization (evaluating duplicacy and superfluousness in **$SelectedMessages** before appending a new object.)

That's all for now.

---
### 06/26/2024
A few more nibbles on **Search-LMHistory**.

I'm putting some thought into how to arrange and represent the results. This is a copy/paste of a reminder comment I put into the code today:

```
#The way I'm going to do this:
# 1. Capitalize the match words in the match message ($MessageIndex)
# 2. Insert each Message into MatchBuffer, plus two new fields: MessagesIndex - index of each message; IsMatching - whether the Message is the matched message)
# 3. For any duplicates:
     # a. If there is a matched message, remove the other, non-matched messages
     # b. If there is not a matched message, remove all duplicates (keep 1)
# 4. Sort by MessageIndex, descending
# 5. Present (format TBD)
```

---
### 06/25/2024
More the same: chipping away at the code in bite-sized chunks. Working on matching Dialog content.

---
### 06/24/2024

I'm making slow progress with **Search-LMHistory**. It's a lot of parameters to account for, and placing the parameters is what is shaping the code.

It's coming together!

---
### 06/23/2024

I didn't have a lot of time today, but I worked more on **Search-LMHistory**.

The *begin {}* block fundamentals are complete (checking/importing files, defining variables). I've got the initial *foreach {}* loop defined in the *process {}* block. This is where comparison operator logic comes into play (**-Match**).

I've added a few more token parameters, like **-SaveAs** and **-WriteProgress**. I *may* 💡 include a **-WriteWarnings** parameter to output what dialog files are missing or bad, if any.

Most of the formatting/output will be in the *end {}* block. I may include a 💡 **-NoConsole** switch parameter to suppress console output (and to avoid retaining data in memory).

That's all for now!

---
### 06/22/2024

Got a start on **Search-LMHistory**. This could get very complicated.

So far I'm working on the parameters. I need to set the output parameters (File/Console?). I think this function is going to be quite long.

One thing I want to do is replace the search terms with CAPITALIZED versions of the word to make the output stand out. I could also include markdown (asterisk asterisk).

Things to do today, will pick this up.

---
### 06/21/2024

I was forced to compromise and integrate tags-management directly into **Start-LMChat**. I wanted to integrate it into **Set-LMCLIOption**, but the way I'd have to go about it would be roundabout and "hacky". I would have had to integrate some string splits and joins to keep the *-UserInput* parameter consistent with all of the other options, where the Dialog File path and the tags could be moved into the function and interpreted correctly. It would have keep the code for **Start-LMChat** shorter, but at a high cost to how I've tried to write this module.

The options are named as follows:

**:tags** - Show the assigned tags

**:atag** - Add tags

**:rtag** - Remove tags

*Add* and *Remove* can also take comma-separated tags.

✅ I need to test the new tags parameters, and confirm they not only get written to the Dialog File, but they also appear in the History File.

**Follow-Up**
Finished testing tags. I added a few improvements to allow sorting/filtering by date with the **Remove-LMHistoryEntry** function.

I also tested the *:priv* option, and it works as intended. I needed to change/clean up the warning output, and accommodate for it in the save prompt code block.

✅ I need to add *:title* to the options, this is something I forgot. I also need to come up with a better options scheme, the four letteres are very limiting.

---
### 06/16/2024

I fixed the two problems with the **Edit-LMSystemPrompt** function, involving the **-Remove** parameter. Bulk removal (and re-adding for any that weren't selected) has been sorted.

I also fixed object typing/sorting for dates in **Select-LMHistoryEntry**. These display in descending order from the "Modified" date in the history file, now.

**Follow-Up**

I struck a compromise with **Get-LMGreeting**: instead of completely wiping out any non-config file configuration, I provided an alternative means to provide a *ManualSettings* file (like with **Get-LMResponse**). 

I also integrated markdown into the function. This took a bit more work than I'd expected; the *$UseGreetingFile* variable became much less important. Formatting/ordering now requires the creation of a Greeting File in memory even if we have no intention of saving the file. Given that the function is a "toy" and a prototype, it's not a problem.

✅ I renamed **Get-LMTemplate** to **New-LMTemplate** because, well, I kept typing it that way. That's what it should be named. There are other function names like this, and I'll rename them as better names occur to me.

---
### 06/15/2024

I have selectively tested options, though I haven't tested the functionality of every option from *end-to-end*. The individual logic works for each piece - which is no guarantee that it will work as a whole. Nonetheless, the things I did test cover the bulk of options and use-cases.

The next step is to address the following bugs and features:

❌ Fill in the **end {}** block of **Start-LMChat**

✅ Add a **clean {}** block to the end of **Start-LMChat**

✅ Write duplicates detection and handling in the **Select-LMHistoryEntry** function

✅ Fix object typing and sorting for the **Start-LMChat -ResumeChat** parameter

✅ Fix and re-write **Edit-LMSystemPrompt -Remove -Bulk** (*doesn't work*)

✅ Convert **Get-LMGreeting** to only use the Config File

✅ Add Set Tags (**:tags**) to **Set-LMCLIOption**, **Get-LMHelp**

✅ Test and validate the **:priv** command

✅ Write the **Search-LMHistory** function


**And these are "admin" tasks:** (*copied over from 05/31/2024*)

⬜️ Better prompts and questions for the greeting generator

⬜️ **Check my functions, and identify which have never been used by any other function**

⬜️ Separate out Public and Private functions (second-to-last thing to do)

⬜️ Build the **psd1** file out

⬜️ Documentation: this one is so important. I need to be very clear that this is built and designed to be easy to use, and is records-oriented: titling, tagging discussions, and searching for them, is what I built.

**Follow-Up:**
Knocked the first two of these out.

Also added clean-up to **Invoke-LMStream**. And put a few strategic 30ms pauses in the prominent *do {}* loops, to cut down on empty/unnecessary looping.

---
### 06/14/2024

I had a strange de-sync issue with the repo where my commit and push worked, but the data in my local repository was out of date at the time that I launched VSCode. I'm not sure how that happened, perhaps a failing drive, failing memory, a VSCode bug, and/or something else. Very strange.

For some reason, I had kept **:show** in **Start-LMChat**, where I'd fully intended for it to be launched via **Set-LMCLIOption**. I moved that into the external function as well.

I put breaks in **Set-LMCLIOption**'s selection switch. Just in case.

I'm going to commit and sync this, do some testing, and perhaps drop in an update.


---
### 06/12/2024

✅ I fully integrated the **:priv** (Privacy Mode) option into **Start-LMChat**.  🚧 I need to test the options system now.

💡 I also need to find some use for the **Start-LMChat** end {} block (*if any*). 

✅ A function to show the current relevant settings as a pop-up would also be very useful (**Show-LMSettings**, integrated as "**:show**).

I need to test the options, and then do a thorough feature test for the chat client.

**Follow-Up**

Fixed a bunch of small issues with command option interpretation.

🐛 I need to fix sorting in the **-ResumeChat** selection prompt.

💡  I *also* forgot the very first ideas I had about the options: the capacity to set tags (**:tags**). I need to include this.

---
### 06/10/2024

Finished testing parameters for **Set-LMCLIOption**, and added the **:gret** parameter toggling Greetings.

I optimized a *lot* of the test conditions for allowing the command to go through. Some tests were made less redundant or eliminated; I found smarter ways to combine sets of tests without making the code hard to understand, and I was able to standardize certain validation patterns for different kinds of inputs.

🐛 **Edit-LMSystemPrompt -Remove -Bulk** does not work. Without **-Bulk** it works fine. I figured this out when trying to clean up after testing the **:newp** input.
✅ I need to fix it. I've wanted to build a better way to remove bulk items, and to remove duplicate items in particular without removing the original or "first" one.

I still need to build **:priv** and **:quit** into **Start-LMChat**.

✅ I also like the idea of completely moving **Get-LMGreeting** over to only use the Config File. I put it off before, but I think I want to do it to make the module consistent.

💡 I would like to add a cheesy ASCII Art banner on start for **Start-LMChat** as well. Very 90s/2000s.

I'm getting closer to completion!
---
### 06/09/2024

Chipping away at validating and setting options. 

**Follow-Up**

I finished **Set-LMCLIOption**. I haven't tested the function as a whole yet, but I did test each individual condition.

**Follow-Up**

The test failed: I could not get the **:mark** commands to work for the life of me. The errors I was able to generate looked like problems with **.Substring()** not working in the function, and **.ToBoolean()** wasn't working either. So I did the expedient and sensible thing: I found a different way to do it, reliably.

I also updated **Get-LMHelp** to provide far more detail and much better formatting, without making it too busy, complicated or cluttered. 💡 I considered writing a system of prompts to give details on how to use each parameter, and I may still do this. Just not yet.

✅ I need to test each remaining option command for **Set-LMCLIOption**. There's enough error checking in it to catch bad input, so at this point I just need to test it for good input.

After I check the parameters, I need to ✅ Integrate **:quit** and **:priv** into the **Start-LMChat** function directly. These two parameters are specific to the chat session.

That's all for now!


---
### 06/08/2024

Got a good start on **Set-LMCLIOption** (renamed). I decided not to use Invoke-Expression and all that, it's adding complexity and danger I don't really want in the code.
":temp" parsing is done, have quite a few more to do:

✅ :q - quit

✅ :h - help

✅ :temp [double]<0.0 - 2.0>             - temperature

✅ :mtok - [int]<-1+>                  - max_tokens

✅ :strm - [boolean]<$True or $False>  - Stream

✅ :save - [boolean]<$True or $False>    - Save Toggle

✅ :mark - [boolean]<$True or $False>    - Markdown

✅ :cond - [int]<2+>                    - Context Depth

✅ :selp - [switch]                      - Select System Prompt

✅ :newp - [string]<[1] - [512]>         - New System Prompt

✅ :priv - [boolean]<$True or $False>    - Privacy Mode (Deletes Dialog file and disables saving)

Have some gardening to do, that's all for now.

**Follow-Up**
Finished gardening. Did the **:mtok** option validation and setting in **Set-LMCLIOption**. I also re-wrote the return object handling in **Start-LMChat** to accommodate a simpler approach (no **Invoke-Expression** to worry about.)

It's shaping up.

---
### 06/07/2024

Personal life got very busy, and then I needed a day off. The break did me good, I was forced to go back into this with a fresh set of eyes.

🐛 I fixed some bugs in the **-LMSystemPrompt** functions. I restructured a few things as well, that were poorly written.

I also started the options handling code for **Start-LMChat**, and it looks like this:

```
try {$InputOption = Confirm-LMCLIOption -Input $UserInput}
catch {Write-Host "Option failed: $($_.Exception.Message)"}

switch ($InputOption.Run){

  $True {

          try {
              $OptionOutput = &(Invoke-Expression -Command ($InputOption.Command) -ErrorAction Stop)
              $OptionSet = $True
          }
          catch {
              Write-Host "Option failed: $($_.Exception.Message)" -ForegroundColor Yellow
              $OptionSet = $False
              continue
          }

          If ($OptionSet){Write-Host "Option succeeded" -ForegroundColor Green}

          continue main

  }

  $False {Write-Host "$($InputOption.Command)" -ForegroundColor Blue}

}


```

**Confirm-LMCLIOption** doesn't exist yet, but we can see from this code that it will do a few specific things:

* It returns an object with properties "Run" (boolean) and "Command" (string)
* The "Run" property contains a value of $True or $False, which signals whether "Command" contains a string (of code)
* The "Command" property contains a string intended to be interpreted and executed (**Invoke-Expression**)

The **$InputOption** Variable receives the result from **Confirm-LMCLIOption**.

If ".Run" is set to $False, then we pass along the result from the object to the console via the ".Command" contents (**Write-Host**).
If it is set to $True, we try to execute, and pass the result to the console via try/catch.

The *purpose* of this structure is to provide a "lean" way to use options to execution functions from within the **Start-LMChat** function. Using Invoke-Expression is frowned upon (it's easy to use to obfuscate malicious code), but in this case it makes it much easier to keep my options parsing and selection code to a minimum in **Start-LMChat**, and mostly residing outside of it.

✅ I need to write duplicates detection and handling in the **Edit-LMSystemPrompt -Remove** function. It's not the highest priority, but it's a bit of a hassle if you have two entries (it deletes both of them.)

That's all for now.

---
### 06/04/2024

Had a day off. Now, I must tackle the settings system.

I've got to make some design decisions about:
* Syntax
* return/error output

For **Syntax**, I think I'll go with:
```
:q - quit
:temp [double]<0.0 - 2.0>             - temperature
:mtoken - [int]<-1+>                  - max_tokens
:stream - [boolean]<$True or $False>  - Stream
:save - [boolean]<$True or $False>    - Save Toggle
:mark - [boolean]<$True or $False>    - Markdown
:depth - [int]<2+>                    - Context Depth
:svsys - [switch]                      - Select System Prompt
:wrsys - [string]<[1] - [512]>         - Write System Prompt
:priv - [boolean]<$True or $False>    - Privacy Mode (Deletes Dialog file and disables saving)

```
A decision has been made. I'll start tomorrow.

I also made improvements to **Select-LMSystemPrompt**, which now enables bulk selection and segments parameters into two sets:
```
    # <none> and -Pin: Sets System Prompt, and commits it to the Config File
    # -AsObject and -Bulk: returns a system prompt, or multiple system prompts as objects
```

This in turn has allowed me to augment **Edit-LMSystemPrompt** with a corresponding **-Remove -Bulk** parameters.
This allows for the deletion of multiple System Prompts from list, i.e, if you're playing around with system prompts and need to clean up the file.

Oh yeah, ✅ **I need to test, fix and validate these two functions.**

That's all for now!

### 06/02/2024

✅ I finished a strong draft version of **Get-LMResponse.** In the process of testing it now.

There are two ways to use **Get-LMResponse**:

**-Settings** input: requires a "ManualSettings" template, filled out:

```
Name                           Value
----                           -----
ContextDepth                   2
max_tokens                     -1
DialogFile                     test2.dialog
port                           1234
UserPrompt                     Please list five species of botanical peppers
SystemPrompt                   You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability.
server                         localhost
temperature                    0.2
```

* For any missing parameters (besides DialogFile, UserPrompt), Defaults (independent of **Config** variables) are used
* You **must** use the **ManualSettings** template for **DialogFile** and **UserPrompt** inputs
  * A script that uses the **-Settings** parameter should "key" off of the Settings hashtable

Without **-Settings** input:

* Uses the **Config** variables (**Global:LMStudioVars**) to pull settings (ContextDepth, MaxTokens, Port, Server, Temperature, SystemPrompt)
* Requires **-UserPrompt** parameter for the input question
* Requires **-DialogFile** parameter to save the Dialog

**I designed it this way with the following use-case in mind:**

* If not specifying **-Settings**, more than likely you're just getting a one-time response from the server.
* If specifying **-Settings**, you're more than likely reading/interpreting output to generate a series of dialogs programmatically
  * This is my use-case:
    * *Start with a query and excess text stripped out*
    * *For each item in a response, parse out the keyword and generate a new question*
    * Repeat recursively

The new function is not intended to be a strictly user-facing client. Use **Start-LMChat** for a user-interfacing chat di8alog.

Some other benefits of building this function:

🐛 I fixed a bug in **Invoke-LMBlob**, stemming from sloppy/quick variable definitions and not thinking the process through.

🐛 I also fixed a bug in **Select-LMSystemPrompt**, where the **\-Pin** parameter wasn't working properly.

**Follow-Up:**

✅ Added and implemented a switch to **Start-LMChat**: **\-PrivateMode**. This will give the ability for a user to not record a chat if they don't want to.

✅ **Remove-LMHistoryEntry** is a new function I need to write. This will come with a few options:

* ✅**-DeleteDialogsToo** will delete the corresponding file
* ✅**-Bulk** will allow the removal of multiple entries (using the **Out-Gridview** option to return multiple)

**Follow-Up:**

**Remove-LMHistoryEntry** is done.

---

### 06/01/2024

Got a decent start on the  **Get-LMResponse** function.

Today's a beautiful day with non-computer things to do, but I'll probably work more on it tonight.

**Follow-Up:**

I've gotten deeper into **Get-LMResponse**. There are a few key features I would like to implement:

✅ Error/warning accumulators, instantiating either a throw (errors) or **Write-Warning** (warnings) - needs to be disablable (**\-SuppressWarnings** switch)

❌**\-SkipConnectionCheck** to disable checking the _/v1/models_ endpoint as a test

✅ Dialog File handling

✅ Allow independent submission of values (temperature, system prompt, etc)

It's coming along, slowly but surely.

**Follow-Up:**

The way that I've implemented Settings with **Get-LMResponse** is that:

- If you **don't** specify **\-Settings**, the function uses the Config settings
- If you **do** specify **\-Settings** but a particular variable doesn't pass validation, the function uses internally-defined defaults.

My reason for doing this is that the **\-Settings** parameter exists to explicitly override the Config File. If settings provided don't pass validation, falling back to the Config File defaults would negate the whole reason for using **\-Settings**: to apply something other than what is configured.

I need to work through the following two sections:
✅ User Prompt Checking for **$LMStudioVars** and **\-Settings** configs, respectively.

✅ Dialog File generation for the above two conditions.

I've made decent enough progress, I'll pick up the Dialog Folder/File management and creation (via template) tomorrow.w

---

### 05/31/2024

I incorporated **Invoke-LMSaveOrOpenUI** into **Import-LMConfig**. 'Twas a simple task.

I thought hard about the **Get-LMResponse** function. I'm going to have to move over a lot of code from **Start-LMChat**.

The parameters could get ugly, ✅ I may force the function to use the "**ManualChatSettings**" template, which I'll need to tweak and reshape for its repurposing. (_It was originally for **Start-LMChat**_)

✅ In **Get-LMResponse**, it would be very useful to generate a Dialog File, and I'm now committed to putting it in. I will use the Dialog File tags field to tag dialogs generated in this way.

That's all for now!

---

### 05/30/2024

I put together ✅ **Edit-LMSystemPrompt**. It takes an **\-Add** or an **\-Remove** parameter. It's pretty simple, actually.

I've been slowing down a bit, but I'm still making myself work on this. I'm determined to "finish" it and make this journal public. It's one of the coolest things I've built in Powershell, and by far the most mature module I've ever written.

Perhaps tomorrow, I'll work on **Search-LMHistory**. If I want an easy day, I'll write **Get-LMResponse**.

✅ With **Get-LMResponse**, I may integrate Dialog File generation. I'm not sure yet.

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

``If ($Global:LMStudioVars.ChatSettings.SystemPrompt -eq "Cancelled" -or ` ``

``$null -eq $Global:LMStudioVars.ChatSettings.SystemPrompt -or ` ``

`$Global:LMStudioVars.ChatSettings.SystemPrompt.Length -eq 0){$Global:LMStudioVars.ChatSettings.SystemPrompt = "$CurrentSysPrompt"}`

`}`

`Else {$Global:LMStudioVars.ChatSettings.SystemPrompt = "Please be polite, concise and informative."}`

`#endregion`

✅ I need to add a switch to **Start-LMChat**: **\-NoSave**. This will give the ability for a user to not record a chat if they don't want to.

✅ I also included **$JobOutput.Dispose()** in the **Invoke-LMStream** function's **Get-Content -Wait** try/catch block. I wonder if some longer term instability I was seeing was because I wasn't properly closing my streamwriters. (_It could also be because I'm always running LMStudio locally when testing_).

---

### 05/27/2024

I had to do some design thinking today, and I realized that to prevent the options system from becoming a cluttered, complicated mess, I'm going to have to do away with the "extensibility" I've maintained.

The extensibility I'm speaking of is the use of certain functions without requiring the config file, or the configuration being loaded.

I've maintained certain parameters to ensure a user could use the program without depending on the config, if they wanted the freedom to use them in a way other than what I designed.

I don't like the idea of forcing people into doing the way I think is best, because what I think is best may not be the best use of the application. By removing that extensibility, I run the risk of forcing users to use the application in a way they don't like.

Or it might not matter at all. Users may really enjoy the "plug and play", relatively uninvolved way I've built it.

I'm hesitant, but I think I'm going to ✅ remove the extensibility. I have to make a decision and live with it, but there are other benefits to removing it:

- The code becomes shorter and more compact
- It eliminates a great deal of ways errors can be introduced
- It removes a lot of required validation
- It will simplify the featureset
- The simplified featureset will simplify the documentation (_which is very important to me_)

That's all for now, no coding today.

---

### 05/27/2024

Busy day yesterday, and took another break.

✅ Instead of integrating markdown into the web client functions (**Invoke-LMBlob/Invoke-LMStream**), I built **Show-LMDialog** to handle Markdown/non-markdown output. It appears to be working pretty well.

🐛 The markdown integration isn't perfect. This time it's not my fault. **Show-Markdown** has some problems that I spent a few hours trying to circumvent but was unable to.

It has a problem with adding extra new-lines, which are not easily stripped out; and it has a problem removing some new-lines, which are not easily put back in.

I fought with a lot of different approaches to solving the problem, but I'm going to call it: for the time-being, it must remain imperfect.

**The list is getting shorter:**

✅ Integrate **Invoke-LMSaveOrOpenUI** into **Import-LMConfig** (_when opening the file without specifying the path_)

✅ Write how the **Start-LMChat** prompt is going to handle option (**:**) inputs. Maybe this should be an auxiliary function

❌ I can add parameters to **Show-LMHelp** to give details for each parameter

...

**These are functions I need to write:**

✅ Write a **Modify-LMSystemPrompts** function (to add to/remove from the list)

⬜️ Write the **Search-LMHistory** function

✅ Write **Get-LMResponse** (single-response query, no console output).
...

**And these are "admin" tasks:** 

(**Moved to 06/15/2024**)

*Moved* Better prompts and questions for the greeting generator

*Moved* Check my functions, and identify which have never been used by any other function**

*Moved* Separate out Public and Private functions (second-to-last thing to do)

*Moved* Build the **psd1** file out

*Moved* Documentation: this one is so important. I need to be very clear that this is built and designed to be easy to use, and is records-oriented: titling, tagging discussions, and searching for them, is what I built.

That's enough for now.

---

### 05/25/2024

I needed a break.

✅ I gutted the validation and complexity in **New-LMConfig** in favor of a single-path approach: define -**BasePath** and everything else is created under this.

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

✅ Fixed problem with fragmentation in **Invoke-LMStream**: if the line fragmented twice, the second fragment wasn't caught.

✅ I need to "go deep" on the **Do/Until** loop for **Invoke-LMStream**. There looks like a lot of room for optimization, and it's cludgy at present. I bet I can improve performance.

💡 I need to come up with a "Pacing" system to detect stuttering from a slow LLM response, and output console text so it's slower but smoother.

✅ History File isn't being updated with **\-ResumeChat,** need to look into this.

✅ Restructured **Invoke-LMStream** from a series of IF statements, to a switch. Tested with PS5/PS7, seems to work just fine.

#### **Follow-Up:**

I sorted a lot of little, meddling bugs out today.

I fixed problems with updating the History File, and problems with setting the "Opener" line in the Dialog Files and in the History File.

I improved **Repair-LMHistoryFile**'s functionality.

I fixed a problem with how I determined the default **MarkDown** property.

Plus everything above.

I forgot to add something to the list below: ✅ Export the System Prompt file in **New-LMConfig.**

That's all for now.

**Edit:** I forgot some things:

❌ I need an empty "Return" in **Start-LMChat** to do nothing (erase current line, don't run). There's a way to erase the current written line, I should experiment with it to make it "transparent".

---

### 05/21/2024

✅ Squashed a bug where I incorrectly terminated in a Default switch (PS5 doesn't assign '.Count' to most non-array objects). This was causing re-opened Dialog files to fail to save. Accommodates both 5/7 now.

✅ Squashed another where the condition I set in the **:main** was causing the "Opener" property to be provisioned in the Dialog file, which leads (downstream) to it missing in the History file.

✅ **\-** I made the System Prompts a template in **Get-LMTemplate,** which will be instantiated by **New-LMConfig**. This will solve the problem of how to guarantee the file and its location.

✅ - I made the "Open Cancelled" output gentler. No reason to throw an error over that.

Added ✅ **ChatSettings.SystemPrompt,** ✅ **ChatSettings.MarkDown** ✅ **ChatSettings.SavePrompt** everywhere:

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

✅ Completed and tested **Repair-LMHistoryFile**, which effectively rebuilds the History File from scratch. Works pretty well.

This is a consolidated list of the work to do:

🚧 Add the following variables to the Config File: \[**Moved**\]

**❌** Implement MarkDown into **Invoke-LMStream** and **Invoke-LMBlob**

✅ Write **Get-LMSystemPrompt** (Involves more file-handling)

✅ Integrate **Get-LMSystemPrompt**  into **Start-LMChat**, and possibly **New-LMConfig**.

**\[Moved\]** Separate out Public and Private functions (second-to-last thing to do)

**\[Moved\]** Integrate **Invoke-LMSaveOrOpenUI** where-ever files are being saved or opened (for name/path validation)

**\[Moved\]** Check my functions, and identify which have never been used by any other function.

**\[Moved\]** Get a start on how the **Start-LMChat** prompt is going to handle option (**:**) inputs. Maybe this should be an auxiliary function

✅ Write a small console script that prompts for a "y/N" answer. (_Or a message box)_

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

The **Select-LMHistoryEntry** function hints at the ✅ **Repair-LMHistoryFile** function, which still needs to be written. It's functionally simple, it'll use the **Convert-LMDialogToHistoryEntry** function to read every Dialog file and reassemble the History File.

**Today I need to:**

✅ Integrate the two new functions into **Start-LMChat**

✅ Sort out History File handling in **Start-LMChat**

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

✅ I also fixed a problem with the **Invoke-LMSaveOrOpenUI** function's name generation: There was a **!Test-Path** instruction in there, and I had a good reason to put it there, but I can't remember why. So I pulled it out.

✅ I decided to strip out the "**\-Lite**" parameter and all of its intricacies, in favor of a new **Get-LMResponse** function. This new function is a basic "_send a prompt, get an answer_" function. It's non-interactive, and built for use with coding (_like, some of my ambitions after I finish this project_).

**Follow-Up:**

Some improvements; started moving into the **Do/Until** loop to get a feel for what order I need to provision and save data.

I need another new function to keep things simple:

✅ A Dialog => Body function:

- Intakes the contents of a Dialog object
- Evaluates the messages in the $Dialog.Messages Array
- References the $ContextDepth
- Builds the array, containing the leading \[system\] role statement, and the previous $ContextDepth number of \[user\] and \[assistant\] messages
- Returns a properly ordered $Body.messages array

**Follow-Up:**

I wrote the DIalog => Body function,(**Convert-LMDialogToBody**) and it's one of the most elegant little functions I've ever written. I had to fix a few things, but it works exactly in the way I need it to work, and helps declutter **Start-LMChat**.

**Priorities:**

**\[moved\]** Add **$Global:LMStudioVars.ChatSettings.SystemPrompt** variable to make this value easilysettable/persistent.

✅ Chase down **Update-HistoryFile**, **Import-HistoryFile,** work out how to save the key Dialog information to the History File

---

### 05/17/2024

Today, I built the **Invoke-LMBlob** function, which isn't complete or polished but should take ✅ maybe 5-10 more minutes to make functional and error-sensitive.

I also established that **.Net Framework 4.5** is the minimum I require for this code to work, due to the use of async methods in the C# code.

Out of curiosity, I used ChatGPT to generate a non-obsolete version of the C# class I'm using for the asynchronous HTTP session. It works great in PS7, standalone, except that it crashed my console. When I run it standalone, it runs okay, but error handling seems to be broken. **❌ Shelving this for now,** let me get everything else working first.

**Out-Gridview** has the curious feature of allowing a user to double-click an entry, which sends a value to a variable. This is **super** helpful for file management.

I will use the **Out-Gridview** functionality to make it easy to:

✅  Resume a previous conversation (using the History File)

**\[Moved\]**  Select a System Prompt (from a statically defined list of system prompts, exported from LM Studio).

I'm also not happy with my **Get-LMGreeting** prompt generator. Functionally, it's perfect; but **\[Moved\]**  I need better prompts and questions.

**\[Moved\]** Also need to go through my functions list and add/strike things off of the list.

#### **Follow-Up:**

✅ I decided to write the path to the config file to $Global:LMConfigFile. This is done by **Import-LMConfig** and **New-LMConfig**. At this time, the only place I'm using the variable is in **Set-LMVariableOptions** (✅  soon to be **Set-LMOptions**) . Not sure if there's a use for it anywhere else.

✅ I changed **$UseLoadedConfig** to **$UseConfig**. Documentation regarding parameters will cover this more ambiguous parameter name.

✅  Shell Functions **Set-LMSystemPrompt** and **Select-LMHistoryFile** were created to use **Out-GridView** as a file selection mechanism.

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

I also ✅ incorporated **Invoke-LMBlob** into **Get-LMGreeting.**

---

### 05/16/2024

I spent a great deal of time last night implementing parameter validation. This is not yet complete.

**Start-LMGreeting** (✅ _soon to be renamed **Get-LMGreeting**_) works great:

![](/Docs/images/get-lmgreeting.gif)

✅ The only code remaining for **Start-LMGreeting** is to write the received information out to the **hello.greeting** file in the folder.

Some additional things I'd like to accomplish today/tomorrow:

- ✅ Incorporate the following fields into the Config File:
  - $Global:LMStudioVars. Endpoints = @{}
    - .Endpoints.ModelURI = \[computed from ServerInfo Server, Port information\]
    - .Endpoints.CompletionURI = \[computed from ServerInfo Server, Port information\]
  - $Global:LMStudioVars.ChatSettings.Greeting = \[boolean\]

#### **Follow-Up:**

I parameterized a few more functions. It didn't get me back a lot of lines, but ti's cleaner now. **❌** **\[Set-LMGlobalVariables\]** and a few others still need parameterizing.

#### **Follow-Up:**

I got a lot of things done today: created all of the Config entries I could ever need; I deleted the superfluous **Set-LMGlobalVariables** and **Initialize-LMVarStore** functions and instead incorporated their utility directly into the (_now renamed_) **Import-LMConfig** and **New-LMConfig** functions.

**Import-LMConfig** will be supplemented by **Set-LMOption \[-Commit\],** which serves to change settings in **Global:LMStudioVars**, as well as ✅ Save the state of **$Global:LMStudioVars** _as-is_.

**\[Moved\]** Mark-down might be a neat thing to experiment with, particularly for the **New-Config** prompts as well as verbose check results.

**Get-LMGreeting** works perfectly, and ✅I need to finish incorporating it into the **Start-LMChat** function.

---

### 05/15/2024

I worked diligently through the input typing problems I had all throughout **Start-LMGreeting**, and fixed the **temperature, max_depth** and **stream** type validations. (_It's important because Powershell's JSON conversions are particular about type, and meet formatting standards._) I then set to task to implement more advanced parameters, where every non-switch parameter is validated. This allowed me to cut out 150 lines of cluttering code.

I'm happy with the flow, the aesthetic and the functionality of it, and **Start-LMGreeting** is a neat toy and a good proof on concept. (_Name may change to **Get-LMGreeting**_).

I've moved on to doing the same for **New-ConfigFile**, and shortly after I'll do **Import-ConfigFile**. **New-ConfigFile** won't benefit as much because I need the prompts, but I also want the input parameters. **Import-ConfigFile** will benefit a little.

I'm on the fence about **$CompletionURI** and **$ModelURI**. I think it would be convenient and "clean" in a small way. The temptation to reduce a whole bunch of duplicate API endpoint paths into a couple variables and parameter names is strong, but I have more important problems to solve at the moment.

✅ Oh yeah, I restored the fragmentation functionality to the **Invoke-LMStream** function. It turns out to be a problem with models that seem to "struggle" with assembling and returning the words. It wasn't my code, it wasn't the computer, it's the model and web server software.

(_Something they could do with LM Studio to improve the web server would be to moderate the stream output speed to be slightly slower than the average of all received characters in a burst. Sounds easy but it's hard to do, but it would make the output slower but less "jittery"_).

(_Alternatively, I could do it myself, from the front-end_).

✅ I also forgot to implement the "**Greeting**" property in the **$Global:LMVars**. Whoops, I'll do that tomorrow.

---

### 05/14/2024

New problems with **Invoke-LMStream**: The job is no longer reliably returning full/whole lines on its own. I need to figure out a way to figure out if the last line in **$JobOutput** is incomplete, and if so, carry it to the next line.

#### **Follow-Up:**

What I think was happening is degraded server performance from my system being up so long. Rebooting made the "fragmentation" issue disappear.

What I think might have been happening is the LLM was being "slow" due to GPU overclock settings being applied (seen this before). Get-Content -Wait was reading the file in between lagtimes in each line-stream, causing the code to return fragmented lines.

Will resume working on **Start-LMGreeting** tomorrow.

#### **Follow-Up:**

✅ Wrote **Set-LMOptions** to create a way to dynamically adjust variables (like _max_tokens, temperature, context_). Wrote it in a way that it doesn't depend on a fixed list of keys.

Finished updating **Import-LMHistoryFile**.

**A few script-wide improvements to do:**

- ✅ I use "_$null -ne $\_ -or $\_.Length -gt 0_" a LOT. It works, but it's not elegant. I will work toward moving to this, instead (where it makes sense):

```
Parameter ValidateScript: [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]

If (!($PSBoundParameters.ContainsKey('PARAMETERNAME'))){}
```

- ✅ **"Temperature", "Max_Tokens" and "ContextDepth"** should be stored, if not in the History File, then in the dialog file. I haven't gotten to writing dialog handling yet, so it's something to do while building is early.

#### **Follow-Up:**

✅ Fixed **Import-LMConfigFile**, added enhancements to **Import-ConfigFile**.

✅Fixed **Initialize-LMVarStore, Set-LMGlobalVariables, Confirm-LMGlobalVariables**.

✅ Pointed all **$Global:LMHistoryVars.HistoryFilePath** entries to **$Global:LMHistoryVars.FilePaths.HistoryFilePath**.

---

### 05/13/2024

In moving over functions to use the **New-LMTemplate** (_which is not done, HistoryFile template has a LOT of hooks_), with a sense of doom I realized I absolutely have to get all of the client settings I need into the config management system. If I don't, it'll be a headache to fix later.

I have much of the Config File (object) formatting done. ✅ **Confirm-LMGlobalVariables** needs to be rewritten.

✅ I need to rewrite **Import-LMConfigFile** to accommodate the new config JSON structure., specifically Lines 261 - 269.

---

### 05/12/2024

✅ Finished the **New-LMTemplate** function; added **temperature,max_tokens,stream,ContextDepth** to Config file and to global settings incorporation.

**TO DO TOMORROW:**
✅ Move functions over to the New-LMTemplate
✅ Remove the old standalone template functions
✅ Evaluate whether I can remove functions I've labeled as such

#### **Follow-Up:**

Had another thought:

✅ I need to convert all "New-LMHistoryFile" calls to the new Template function.
✅  **New-LMHistoryFile** does nothing but save an arbitrary file, it's a pointless function. I just have to do:

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
✅Update the Client to use the complete functions I have (should shorten the code substantially)
Review this, and likely simplify/replace it (Client):\`

✅ Need to check if this is still valid:

```
If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$Hist...
```

---

### 05/10/2024

Finished **Import-LMConfigFile**, which required parameterizing a whole bunch of functions and fixing various checks/validations. New-LMConfigFile comes next.✅ **Create-LMConfigFile** will have the following parameters:

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

✅ History File will keep an index of Dialog files and some information about them (Date, opening line, model, Dialog (array))✅ Dialogs themselves will be stored as either random or sequentially named files, with the following columns:

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