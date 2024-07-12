### Start-LMChat Commands


##### :quit 
Exits the application

##### **:privmode**
Enables Privacy Mode

Once enabled, Privacy Mode cannot be disabled for the duration of the chat session.

If the Start-LMChat session is new, **:privmode** deletes the Dialog file and History file entry.

If the Start-LMChat session was resumed (*-ResumeChat*), **:privmode** restores the Dialog file back to its state prior to the resumed session, and updates the History file entry.


