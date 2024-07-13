### Start-LMChat Commands


##### :quit 
Exits the application


##### **:privmode**
Enables Privacy Mode

Once enabled, Privacy Mode cannot be disabled for the duration of the chat session.

If the Start-LMChat session is new, **:privmode** deletes the Dialog file and History file entry.

If the Start-LMChat session was resumed (*-ResumeChat*), **:privmode** restores the Dialog file back to its state prior to the resumed session, and updates the History file entry.


##### **:show**
Shows the current settings:

- Server
- Port
- Temperature
- Max Tokens
- Context Depth
- Interpret Markdown (true/false)
- Stream Console Output (true/false)
- Prompt for Initial Save (true/false)
- Greeting on Start (true/false)
- System Prompt
- History File
- Dialog File


##### **:selprompt**
Presents a UI prompt to select a system prompt.

When a prompt is selected, the prompt is also *pinned* to your Config File. *Pinning* makes the selected prompt persistent, until it is changed.


##### **:temp** <0.0 - 2.0>
Sets the LLM temperature to a range between 0.0 and 2.0.

Lower is *less* creative. Higher is *more* creative.


##### **:maxtoks** <-1 | 1+>
Sets the Max Tokens to either **-1** (*no limit*), or an integer of **1 or greater**.


##### **:stream ** <true | false>
Sets token streaming to either **true** (*on*) or **false** (*off*).

Streaming is the feature that writes characters as they are received. It has a **.Net Framework 4.5** (*minimum*) dependency, which not all people may have.

If you have problems with streaming, setting this to *false* will disable it. When disabled, the text will be delivered as soon as the response is received and completed.


##### **:saveprompt** <true | false>
Sets the Save Prompt for the Dialog File to either **true** (*on*) or **false** (*off*).

When set to *true*, Start-LMChat will present a save prompt every time you initiate a brand new dialog. (*Doesn't apply with -ResumeChat*)

When set to *false*, Start-LMChat will automatically select and save the Dialog file to the Dialog folder.


##### **:markdown** <true | false>
Sets markdown interpretation of LLM output to either **true** (*on*) or **false** (*off*).

Markdown is the markup language that displays text in the format within this document, for example.

Markdown support requires Powershell 7.

If you do not want to install PSH7, or you're having problems with markdown interpretation (*it's hit or miss in Powershell*), disable it by setting it to **false**.


##### **:greeting** <true | false>
Turns the greeting (at start) to either **true** (*on*) or **false** (*off*).

It's completely understandable if people don't want this feature. It was a prototyping toy I made to get the design basis of this module together, and to work through initial implementation issues.


##### **:condepth** <2+>
Sets the context depth to an **even number** of **2** or greater.


