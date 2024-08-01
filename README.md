# LMStudio-Client

A feature-rich LMStudio console client for Powershell.

![](/Docs/images/alpacas-prompt.gif)

**Current Version:** 0.5.4
**Last Code Update:** 07/31/2024

## Features:

- Use LMStudio chat from any computer on your network!

- Records and saves LLM chat dialogs locally
  - Built-in file management, indexing (*search* will be included)
  - Resume and continue previous dialogs
  - Search the contents of your chat history

- Persistent configuration management:
  - Settings are preserved in a configuration file
  - Settings can be modified and saved easily

- And more!
  - Seriously, there's a lot of functionality built into this module.
  - What these are and how to use them will be included in the documentation.


## Documentation

The [Quick-Start Guide](./Docs/Section/Quick-Start-Guide.md) is a no-frills and no-explanations guide on getting the module up and running.

It assumes several prerequisites:
- LM Studio is running 
- The LM Studio web server is started in the software

The [Slow-Start Guide](./Docs/Section/Slow-Start-Guide.md) is an index of more detailed documentation on how to use the module.

The Slow-Start Guide documentation is in the process of being written. Anything below "🚧 **Below in progress:**" is not complete.

I maintain a [Development Journal](./Docs/Dev-Journal.md) to record and track my priorities, and to rationalize my design decisions.

It may be dry to some, and not dry to othres.

Last Update was **July 31, 2024**.

## Notes/Addendum:

**07/18/2024** I have created the PSD1 file so these functions can be imported as a proper Powershell module. See the [**dev journal**](./Docs/Dev-Journal.md) for details.

**07/07/2024** ~~The current version of the code does **not** work with Powershell 5. I will attempt to resolve this issue, and I'm not sure when it was first introduced.~~ This issue is caused by the use of the **clean {}** block in Powershell, which I learned was only introduced in 7.3.

I've commented out the **clean {}** block (for now).