# Other Tools and Utilities
This section covers various other tools included in the LMStudio-Client module.

## Retrieve the loaded LMStudio Model
To retrieve the currently loaded model from LM Studio, run the following command:

```
Get-LMModel
```

This command outputs the model in a similar format to this:

```
lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q6_K.gguf
```

## Using this Module Programmatically
The purpose of **Get-LMResponse** is to provide a programmatic interface for LMStudio. It is a way to send and receive responses in a way that allows coding and experimentation. (*It could be used to "internet-connect" the LLM!*)

This section contains a usage example to demonstrate how this function may be used.

### Create Manual Settings Template
The recommended way to use **Get-LMResponse** is to load a Manual Settings template:

```
$Settings = New-LMTemplate -Type ManualSettings

$Settings | Format-Table

Name                           Value
----                           -----
stream                         True
temperature                    0.7
DialogFile
max_tokens                     -1
server                         localhost
UserPrompt
SystemPrompt                   You are a helpful, smart, kind, personal and open chat partner. You always fulfill the user's requests to the best of your ability.
Markdown                       True
ContextDepth                   10
port                           1234
```

### Fill In Template Values
You can set the template values like this:

```
$Settings.temperature = 0.2 #Reduce creativity

$Settings.UserPrompt = "List 30 non-alcoholic beverage companies. Please provide the output in CSV format. Do not return anything that does not fit in the CSV format."
```

**Note:** Many settings are auto-populated from your loaded config. Not all settings are used by **Get-LMResponse**.

### Send your Request to the LLM
After your template values are populated, you can send your request to LM Studio like this:

```
$Results = Get-LMResponse -Settings $Settings
```

### Parse The Output
What you do with your LLM response depends on the format you've instructed the LLM to return.

In this example, the response is in comma-separated values (CSV) format. It can be consumed in Powershell using this command:

```
$Results | ConvertFrom-Csv | Format-Table

Company Name             Description
------------             -----------
Aquafina                 Purified water brand owned by PepsiCo
Fanta                    Fruit-flavored soft drink brand owned by The Coca-Cola Company
Gatorade                 Sports drink brand owned by PepsiCo
Hansen's Natural Sodas   Craft soda brand
IZZE                     Organic and natural juice brand
Kevita                   Probiotic-infused sparkling water brand
LaCroix                  Sparkling water brand owned by National Beverage Corp.
Moxie                    Ginger-flavored soft drink brand
Nestea                   Iced tea brand owned by Nestle
Polar Seltzer            Sparkling water brand
Sunkist                  Orange juice and other citrus-flavored beverages brand
Zevia                    Zero-calorie, naturally sweetened soda brand
Honest Tea               Organic and fair-trade tea brand
Voss Water               Premium bottled water brand
Fresca                   Citrus-flavored soft drink brand owned by The Coca-Cola Company
Tropicana                Orange juice and other fruit-flavored beverages brand
Sobe                     Energy drink brand owned by PepsiCo
Fuze Tea                 Iced tea brand owned by PepsiCo
Ginger Ale Canada        Ginger ale brand
Schweppes                Tonic water and other mixer brands
Ace Juice Company        Juice brand
Evian Water              Mineral water brand
Fiji Water               Premium bottled water brand
Celsius                  Energy drink brand
Suja Juice               Cold-pressed juice brand
Mission Foods            Organic and natural beverage brand
Zola Hydrating Beverages Coconut water brand
Diet Rite                Diet soda brand owned by Dr Pepper Snapple Group
Seagram's                Ginger ale and other mixer brands
Stur Water Enhancer      Water flavor enhancer brand
```

Your imagination (*and use-case*) is the limit!

## The Greeting Toy
**Get-LMGreeting** was the prototype used for building **Start-LMChat**. Every core component involving client/server interactions was worked out by creating this widget.

It's near and dear to my heart, and so I've decided to keep it in the module.

The way it works is pretty simple: **Get-LMGreeting** attempts to generate a non-deterministic question and response, by combining multiple constraints in a user prompt:

```
Get-LMGreeting
You: Talk like a valley girl. Please greet me in a unique and fun way!

AI: Oh my gosh, hi there, fer shure! *bounces up and down excitedly* Like, welcome to our totally tubular conversation, dude! I'm, like, so stoked to be chatting with you!

*twirls around* You're, like, the best, and I'm, like, honored to be talking to you, fer shure! So, like, what's up? Want to dish about something totally fabulous or just, like, hang out and chat?
```

```
Get-LMGreeting
You: Talk like a valley girl. Please greet me in a unique and fun way!

AI: Oh my gosh, like, hi there, cutie pie! *giggles* I'm, like, soooo excited to be talking to you, fer shure!

*twirls around* You're, like, totally awesome, and I'm, like, honored to be chatting with you, 'kay? So, like, let's get this convo started, stat! We can, like, talk about anything from the latest fashion trends to our fave TV shows... or, like, just hang out and be all chatty, fer shure!

*breaks into song* "You're a total babe, and I'm so glad we're chatting, 'cause you're, like, totally rad!"
```

```
Get-LMGreeting
You: Talk like Arnold Schwarzenegger. Choose a proper noun that contains these three letters: H, V, A. Then provide a fact about the chosen proper noun.

AI: Ahh, hello there, my friend! Ze Governator here, and I'm gonna give you ze facts, ja?

Ze proper noun I've chosen, eet ees... Havanna! Ja, ze capital city of Cuba, eet ees a beautiful place, no?

Now, let me tell you something about Havanna. Did you know that Havanna ees home to one of ze oldest and most famous cigar factories in ze world? Ja, ze Partagás Factory, eet ees been producing high-quality cigars since 1845! Ze Cubans, zay take pride in their cigars, ja?

So dere you haff it, my friend. Havanna, eet ees a city of passion and beauty, no?
```

```
Get-LMGreeting
You: Talk like you're porky pig. Please try to baffle me.

AI: (Stuttering) W-w-well, th-th-that's all folks! Er, I mean... (chuckles nervously) Oh boy, oh boy! Let me t-t-try to p-p-puzzle ya!

You see, I've got a w-w-word that's got three l-l-letters in it: F, E, and D. And I'm gonna ask you to g-g-guess what word it is! (Giggles) But here's the c-c-catch: I'm only going to give you h-h-hints!

H-h-hint number one: It's a p-p-place where people go to r-r-relax and have f-f-fun. (Winks)

H-h-hint number two: It's got something to do with w-w-water! (Giggles)

Now, can you g-g-guess what word it is? (Stuttering) I-I-I don't think so... (Chuckles nervously) Oh boy, oh boy!

(Leans in close) W-w-want a c-c-clue? It's not the ocean! (Winks)
```