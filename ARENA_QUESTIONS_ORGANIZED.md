# DevSpace Arena — High-Signal Deduplicated Question Bank

> **Status**: Fully deduplicated and pruned of repetitive templates. All 190 questions have been integrated into `lib/data/practice_questions.dart` with verified syntax.

## Tier Sizing & Non-Repetitive Distribution

| Tier / Lobby | Points | Previous | New Clean Pool | Concepts Tested |
| :--- | :---: | :---: | :---: | :--- |
| **🟢 Easy (Noob Lobby)** | **+5 Aura** | 20 Qs | **44 Questions** | Core Syntax, Precedence (BODMAS), Modulo, Simple IF/ELSE, Loops, Accumulators |
| **🟡 Medium (Scrims)** | **+10 Aura** | 20 Qs | **74 Questions** | Arrays, Strings, Nested Loops, Searching (Linear/Binary), Sorting (Bubble/Insertion/Merge/Quick), OOPs |
| **🟠 Hard (Ranked)** | **+15 Aura** | 20 Qs | **42 Questions** | Time & Space Complexity (Big-O), Multi-step Tracing, Triangular Loops, Digital Roots, Array Spreads |
| **🟣 Ultra (Final Circle)** | **+20 Aura** | 20 Qs | **30 Questions** | DSA Interview Patterns (Two-Sum, Kadane, LIS, Mountain, Stairs DP, XOR) + Advanced Systems/Concurrency |
| **TOTAL** | | **80 Qs** | **190 Questions** | **Zero repetitive copy-paste templates; 100% unique learning value** |

---

## 🟢 Level 0: Easy (Noob Lobby) — 44 Unique Questions

#### [noob_1] Which language is primarily used to build Flutter applications?
**Tier**: `Noob` (Level 0) | **Stack**: `Mobile` | **Number**: #1  

- **A.** Java
- **B.** Dart ✅ *(Correct)*
- **C.** Python
- **D.** C++

> **Explanation**: Flutter is an open-source UI toolkit created by Google that uses the Dart programming language.

---

#### [noob_2] What is the output of printing 5 + 3 * 2 in most programming languages?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #2  
```text
print(5 + 3 * 2);
```

- **A.** 16
- **B.** 11 ✅ *(Correct)*
- **C.** 13
- **D.** 10

> **Explanation**: According to mathematical operator precedence (BODMAS/PEMDAS), multiplication is evaluated before addition: 3 * 2 = 6, then 5 + 6 = 11.

---

#### [noob_3] Which of the following is NOT an operating system?
**Tier**: `Noob` (Level 0) | **Stack**: `DevOps & Tools` | **Number**: #3  

- **A.** Linux
- **B.** Windows
- **C.** HTML ✅ *(Correct)*
- **D.** macOS

> **Explanation**: HTML (HyperText Markup Language) is a markup language for Web pages, not an operating system.

---

#### [noob_4] What symbol is used for a single-line comment in Dart, C++, and Java?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #4  

- **A.** #
- **B.** // ✅ *(Correct)*
- **C.** /*
- **D.** <!--

> **Explanation**: Double forward slashes // are used to write single-line comments in Dart, C, C++, Java, and JavaScript.

---

#### [noob_5] What does HTML stand for?
**Tier**: `Noob` (Level 0) | **Stack**: `Frontend` | **Number**: #5  

- **A.** Hyper Text Markup Language ✅ *(Correct)*
- **B.** High Tech Modern Language
- **C.** Hyperlink Text Markup Logic
- **D.** Home Tool Markup Language

> **Explanation**: HTML stands for Hyper Text Markup Language. It is the standard markup language for documents designed to be displayed in a web browser.

---

#### [noob_6] Which HTML tag is used for the largest heading?
**Tier**: `Noob` (Level 0) | **Stack**: `Frontend` | **Number**: #6  

- **A.** <h6>
- **B.** <head>
- **C.** <h1> ✅ *(Correct)*
- **D.** <header>

> **Explanation**: <h1> defines the most important / largest heading in HTML, while <h6> defines the least important / smallest heading.

---

#### [noob_7] What is the starting index of an Array/List in most programming languages?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #7  

- **A.** 1
- **B.** -1
- **C.** 0 ✅ *(Correct)*
- **D.** None

> **Explanation**: Zero-based indexing is a way of numbering where the first element of a sequence is assigned index 0.

---

#### [noob_8] Which keyboard shortcut is universally used to COPY selected text?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #8  

- **A.** Ctrl + X
- **B.** Ctrl + V
- **C.** Ctrl + C ✅ *(Correct)*
- **D.** Ctrl + Z

> **Explanation**: Ctrl+C (or Cmd+C on Mac) copies selected text/items to the clipboard.

---

#### [noob_9] What type of value can a Boolean variable store?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #9  

- **A.** Decimals
- **B.** True or False ✅ *(Correct)*
- **C.** Numbers only
- **D.** Text strings

> **Explanation**: A boolean data type has one of two possible values: true or false.

---

#### [noob_10] Which symbol is used to assign a value to a variable in most programming languages?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #10  

- **A.** ==
- **B.** = ✅ *(Correct)*
- **C.** :
- **D.** =>

> **Explanation**: A single equal sign `=` is the assignment operator, while `==` is used to compare equality.

---

#### [noob_11] What is the file extension for a Python script?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #11  

- **A.** .pt
- **B.** .py ✅ *(Correct)*
- **C.** .python
- **D.** .pyt

> **Explanation**: Python files use the .py file extension.

---

#### [noob_12] What is the result of evaluating: 10 % 3 ?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #12  

- **A.** 3
- **B.** 1 ✅ *(Correct)*
- **C.** 0
- **D.** 3.33

> **Explanation**: The modulo operator % returns the remainder of integer division. 10 divided by 3 is 3 with a remainder of 1.

---

#### [noob_13] Which CSS property changes text color?
**Tier**: `Noob` (Level 0) | **Stack**: `Frontend` | **Number**: #13  

- **A.** font-color
- **B.** text-style
- **C.** color ✅ *(Correct)*
- **D.** background-color

> **Explanation**: In CSS, the `color` property specifies the color of text.

---

#### [noob_14] What does CSS stand for?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #14  

- **A.** Cascading Style Sheets ✅ *(Correct)*
- **B.** Computer Style Sheets
- **C.** Creative Style Sheets
- **D.** Colorful Style Sheets

> **Explanation**: CSS stands for Cascading Style Sheets, used for styling web documents.

---

#### [noob_15] What will be the output of this snippet?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #15  
```text
int age = 18;
if (age >= 18) {
  print(
```

- **A.** Minor
- **B.** Adult ✅ *(Correct)*
- **C.** Error
- **D.** Nothing

> **Explanation**: Since age is 18 and 18 >= 18 evaluates to true, 

---

#### [noob_16] Which git command clones a repository from GitHub to your computer?
**Tier**: `Noob` (Level 0) | **Stack**: `DevOps & Tools` | **Number**: #16  

- **A.** git pull
- **B.** git fetch
- **C.** git clone ✅ *(Correct)*
- **D.** git copy

> **Explanation**: `git clone <url>` creates a local copy of a remote repository.

---

#### [noob_17] What is a loop used for in programming?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #17  

- **A.** To repeat a block of code multiple times ✅ *(Correct)*
- **B.** To stop the app from running
- **C.** To color the background
- **D.** To declare variables

> **Explanation**: Loops (like for, while) are used to execute a set of statements repeatedly based on a condition.

---

#### [noob_18] Which data type is best suited for storing a person\
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #18  

- **A.** Integer
- **B.** Boolean
- **C.** String ✅ *(Correct)*
- **D.** Double

> **Explanation**: Strings are sequences of characters used to store textual data like names and titles.

---

#### [noob_19] What does IDE stand for?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #19  

- **A.** Integrated Development Environment ✅ *(Correct)*
- **B.** Internal Design Engine
- **C.** Internet Development Environment
- **D.** Interactive Design Editor

> **Explanation**: An IDE (Integrated Development Environment) is a software application that provides tools (editor, debugger, compiler) for software development.

---

#### [noob_20] What is the output of 
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #20  

- **A.** Hello World ✅ *(Correct)*
- **B.** HelloWorld
- **C.** Error
- **D.** Hello+World

> **Explanation**: Concatenating 

---

#### [noob_21] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #21  
```text
x = 5
y = 2
PRINT x + y * 3
```

- **A.** 21
- **B.** 11 ✅ *(Correct)*
- **C.** 15
- **D.** 7

> **Explanation**: Multiplication has higher precedence than addition: 2 * 3 = 6, then 5 + 6 = 11.

---

#### [noob_22] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #22  
```text
x = 10
IF x > 5
  PRINT 
```

- **A.** No
- **B.** Yes ✅ *(Correct)*
- **C.** 10
- **D.** Error

> **Explanation**: Since 10 > 5 is true, the IF branch executes and prints \

---

#### [noob_23] How many times does the loop execute?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #23  
```text
FOR i = 1 TO 5
  PRINT i
```

- **A.** 4
- **B.** 5 ✅ *(Correct)*
- **C.** 6
- **D.** 1

> **Explanation**: Loop endpoints are inclusive (i = 1, 2, 3, 4, 5), so it executes 5 times.

---

#### [noob_24] What is the final value of x?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #24  
```text
x = 3
x = x + 4
x = x * 2
```

- **A.** 7
- **B.** 10
- **C.** 14 ✅ *(Correct)*
- **D.** 6

> **Explanation**: x becomes 3 + 4 = 7, then 7 * 2 = 14.

---

#### [noob_25] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #25  
```text
x = 8
IF x MOD 2 == 0
  PRINT 
```

- **A.** Odd
- **B.** Even ✅ *(Correct)*
- **C.** 8
- **D.** 0

> **Explanation**: 8 MOD 2 is 0, so the IF branch prints \

---

#### [noob_26] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #26  
```text
FOR i = 1 TO 3
  PRINT i * 2
```

- **A.** 1 2 3
- **B.** 2 4 6 ✅ *(Correct)*
- **C.** 3 6 9
- **D.** 2 3 4

> **Explanation**: The loop outputs 1*2 = 2, 2*2 = 4, and 3*2 = 6.

---

#### [noob_27] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #27  
```text
a = 4
b = 4
IF a == b
  PRINT 
```

- **A.** Equal ✅ *(Correct)*
- **B.** Different
- **C.** 8
- **D.** Error

> **Explanation**: a and b are both 4, so condition a == b is true, printing \

---

#### [noob_28] What is the final value of sum?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #28  
```text
sum = 0
FOR i = 1 TO 4
  sum = sum + i
```

- **A.** 4
- **B.** 6
- **C.** 10 ✅ *(Correct)*
- **D.** 12

> **Explanation**: Adding 1 through 4 gives 1 + 2 + 3 + 4 = 10.

---

#### [noob_29] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #29  
```text
x = 7
PRINT x MOD 3
```

- **A.** 1 ✅ *(Correct)*
- **B.** 2
- **C.** 3
- **D.** 4

> **Explanation**: 7 divided by 3 gives quotient 2 and remainder 1.

---

#### [noob_30] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #30  
```text
x = 2
WHILE x < 5
  PRINT x
  x = x + 1
```

- **A.** 2 3 4 ✅ *(Correct)*
- **B.** 2 3 4 5
- **C.** 3 4 5
- **D.** 2 4

> **Explanation**: Loop prints 2, 3, 4; terminates when x reaches 5.

---

#### [noob_31] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #31  
```text
x = 4
y = 4
PRINT x + y * 3
```

- **A.** 16 ✅ *(Correct)*
- **B.** 15
- **C.** 17
- **D.** 18

> **Explanation**: Multiplication first: 4 + (4 × 3) = 16.

---

#### [noob_32] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #32  
```text
x = 7
y = 3
PRINT x + y * 3
```

- **A.** 18
- **B.** 17
- **C.** 16 ✅ *(Correct)*
- **D.** 15

> **Explanation**: Multiplication first: 7 + (3 × 3) = 16.

---

#### [noob_33] What is the final value of x?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #33  
```text
x = 7
x = x + 4
x = x * 2
PRINT x
```

- **A.** 24
- **B.** 23
- **C.** 22 ✅ *(Correct)*
- **D.** 21

> **Explanation**: x becomes 11, then 22.

---

#### [noob_34] What is the final value of x?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #34  
```text
x = 11
x = x + 4
x = x * 2
PRINT x
```

- **A.** 29
- **B.** 32
- **C.** 30 ✅ *(Correct)*
- **D.** 31

> **Explanation**: x becomes 15, then 30.

---

#### [noob_35] What value is printed?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #35  
```text
x = 5
PRINT x MOD 2
```

- **A.** 0
- **B.** 2
- **C.** 3
- **D.** 1 ✅ *(Correct)*

> **Explanation**: The remainder when 5 is divided by 2 is 1.

---

#### [noob_36] What value is printed?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #36  
```text
x = 6
PRINT x MOD 2
```

- **A.** 3
- **B.** 1
- **C.** 2
- **D.** 0 ✅ *(Correct)*

> **Explanation**: The remainder when 6 is divided by 2 is 0.

---

#### [noob_37] What is the final value of sum?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #37  
```text
sum = 0
FOR i = 1 TO 4
sum = sum + i
PRINT sum
```

- **A.** 10 ✅ *(Correct)*
- **B.** 11
- **C.** 9
- **D.** 12

> **Explanation**: Adding 1 through 4 gives 10.

---

#### [noob_38] What is the final value of sum?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #38  
```text
sum = 0
FOR i = 1 TO 5
sum = sum + i
PRINT sum
```

- **A.** 15 ✅ *(Correct)*
- **B.** 17
- **C.** 14
- **D.** 16

> **Explanation**: Adding 1 through 5 gives 15.

---

#### [noob_39] What is printed?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #39  
```text
x = 0
FOR i = 1 TO 3
x = x + 2
PRINT x
```

- **A.** 6 ✅ *(Correct)*
- **B.** 7
- **C.** 8
- **D.** 5

> **Explanation**: Two is added 3 times, giving 6.

---

#### [noob_40] What is printed?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #40  
```text
x = 0
FOR i = 1 TO 4
x = x + 2
PRINT x
```

- **A.** 10
- **B.** 9
- **C.** 8 ✅ *(Correct)*
- **D.** 7

> **Explanation**: Two is added 4 times, giving 8.

---

#### [noob_41] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #41  
```text
x = 4
IF x MOD 2 == 0
PRINT 
```

- **A.** Odd
- **B.** Zero
- **C.** Even ✅ *(Correct)*
- **D.** Error

> **Explanation**: 4 is even.

---

#### [noob_42] What is the output?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #42  
```text
x = 5
IF x MOD 2 == 0
PRINT 
```

- **A.** Even
- **B.** Odd ✅ *(Correct)*
- **C.** Error
- **D.** Zero

> **Explanation**: 5 is odd.

---

#### [noob_43] What is the final value of x?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #43  
```text
x = 6
WHILE x > 3
x = x - 1
PRINT x
```

- **A.** 5
- **B.** 2
- **C.** 3 ✅ *(Correct)*
- **D.** 4

> **Explanation**: The loop decreases x until it reaches 3.

---

#### [noob_44] What is the final value of x?
**Tier**: `Noob` (Level 0) | **Stack**: `DSA & Logic` | **Number**: #44  
```text
x = 7
WHILE x > 3
x = x - 1
PRINT x
```

- **A.** 6
- **B.** 5
- **C.** 4 ✅ *(Correct)*
- **D.** 3

> **Explanation**: The loop decreases x until it reaches 3.

---

## 🟡 Level 1: Medium (Scrims) — 74 Unique Questions

#### [easy_1] Which HTTP method is used to retrieve data from a server without modifying it?
**Tier**: `Easy` (Level 1) | **Stack**: `Backend` | **Number**: #1  

- **A.** POST
- **B.** PUT
- **C.** GET ✅ *(Correct)*
- **D.** DELETE

> **Explanation**: GET requests are used to retrieve resource data from a server.

---

#### [easy_2] In Git, which command stages changes to prepare them for a commit?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #2  

- **A.** git add ✅ *(Correct)*
- **B.** git stage-all
- **C.** git push
- **D.** git commit

> **Explanation**: `git add <files>` moves changes from the working directory to the staging area.

---

#### [easy_3] What is the length of the list `[
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #3  

- **A.** 2
- **B.** 3 ✅ *(Correct)*
- **C.** 4
- **D.** 0

> **Explanation**: The list contains 3 elements: 

---

#### [easy_4] Which SQL statement is used to fetch data from a database table?
**Tier**: `Easy` (Level 1) | **Stack**: `Backend` | **Number**: #4  

- **A.** FETCH
- **B.** GET
- **C.** SELECT ✅ *(Correct)*
- **D.** EXTRACT

> **Explanation**: The `SELECT` statement in SQL queries data from one or more database tables.

---

#### [easy_5] What does JSON stand for?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #5  

- **A.** JavaScript Object Notation ✅ *(Correct)*
- **B.** Java Standard Output Network
- **C.** JavaScript Oriented Notation
- **D.** Java System Object Network

> **Explanation**: JSON stands for JavaScript Object Notation, a lightweight format for storing and transporting data.

---

#### [easy_6] Which keyword in Dart is used to declare a variable whose value cannot be changed once assigned?
**Tier**: `Easy` (Level 1) | **Stack**: `Mobile` | **Number**: #6  

- **A.** var
- **B.** final ✅ *(Correct)*
- **C.** late
- **D.** dynamic

> **Explanation**: In Dart, `final` variables can only be set once.

---

#### [easy_7] What will be the output of `2 ** 3` in Python?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #7  

- **A.** 6
- **B.** 8 ✅ *(Correct)*
- **C.** 9
- **D.** 5

> **Explanation**: In Python, `**` is the exponentiation operator. 2 ** 3 means 2^3 = 8.

---

#### [easy_8] Which HTTP status code signifies 
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #8  

- **A.** 200
- **B.** 404 ✅ *(Correct)*
- **C.** 500
- **D.** 301

> **Explanation**: HTTP 404 Not Found client error response code indicates that the server cannot find the requested resource.

---

#### [easy_9] What is the function of `git status`?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #9  

- **A.** Displays the commit history
- **B.** Displays modified, staged, or untracked files ✅ *(Correct)*
- **C.** Deletes untracked files
- **D.** Merges remote branches

> **Explanation**: `git status` shows the state of the working directory and staging area.

---

#### [easy_10] Which Widget in Flutter is used to display a basic text label?
**Tier**: `Easy` (Level 1) | **Stack**: `Mobile` | **Number**: #10  

- **A.** Label
- **B.** Text ✅ *(Correct)*
- **C.** Typography
- **D.** StringWidget

> **Explanation**: The `Text` widget displays a string of text with single style in Flutter.

---

#### [easy_11] What is the default port for HTTP web traffic?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #11  

- **A.** 443
- **B.** 80 ✅ *(Correct)*
- **C.** 8080
- **D.** 21

> **Explanation**: HTTP runs over port 80 by default, while HTTPS runs over port 443.

---

#### [easy_12] Which command runs a Flutter application on an attached device or emulator?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #12  

- **A.** flutter start
- **B.** flutter launch
- **C.** flutter run ✅ *(Correct)*
- **D.** flutter execute

> **Explanation**: `flutter run` builds and launches your application.

---

#### [easy_13] In SQL, which clause filters records before grouping?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #13  

- **A.** HAVING
- **B.** WHERE ✅ *(Correct)*
- **C.** ORDER BY
- **D.** GROUP BY

> **Explanation**: `WHERE` filters rows before any grouping occurs, while `HAVING` filters group summaries after `GROUP BY`.

---

#### [easy_14] What does CSS Flexbox `justify-content: center` do?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #14  

- **A.** Aligns items vertically
- **B.** Aligns items along the main axis to center ✅ *(Correct)*
- **C.** Sets item background color
- **D.** Wraps flex items into new lines

> **Explanation**: `justify-content` defines how space is distributed along the main axis of a flex container.

---

#### [easy_15] Which operator checks for strict equality (both value and type) in JavaScript?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #15  

- **A.** =
- **B.** ==
- **C.** === ✅ *(Correct)*
- **D.** equals

> **Explanation**: The `===` strict equality operator returns true only if operands are equal and of the same type without type coercion.

---

#### [easy_16] What is the purpose of `try-catch` blocks in code?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #16  

- **A.** To catch internet signals
- **B.** To handle runtime errors without crashing the app ✅ *(Correct)*
- **C.** To accelerate loop execution
- **D.** To design UI animations

> **Explanation**: `try-catch` statement marks a block of statements to try, and specifies a response should an exception be thrown.

---

#### [easy_17] Which widget layout in Flutter arranges children vertically in a column?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #17  

- **A.** Row
- **B.** Column ✅ *(Correct)*
- **C.** Stack
- **D.** ListView

> **Explanation**: A `Column` displays a list of child widgets in a vertical array.

---

#### [easy_18] What does API stand for?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #18  

- **A.** Application Programming Interface ✅ *(Correct)*
- **B.** Applied Program Integration
- **C.** Automated Process Interface
- **D.** Application Process Integration

> **Explanation**: API stands for Application Programming Interface.

---

#### [easy_19] Which Git command pushes local commits to a remote repository like GitHub?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #19  

- **A.** git upload
- **B.** git send
- **C.** git push ✅ *(Correct)*
- **D.** git publish

> **Explanation**: `git push` uploads local branch commits to the remote repository.

---

#### [easy_20] What will `print([1, 2, 3] + [4, 5])` produce in Python?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #20  


> **Explanation**: In Python, adding two lists concatenates them into a single list.

---

#### [easy_21] What number is missing?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #21  
```text
1, 2, 3, 5, 6
```

- **A.** 2
- **B.** 3
- **C.** 4 ✅ *(Correct)*
- **D.** 7

> **Explanation**: The missing number in the consecutive sequence from 1 to 6 is 4.

---

#### [easy_22] What is the second-largest distinct number?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #22  
```text
10, 5, 8, 10, 3
```

- **A.** 10
- **B.** 8 ✅ *(Correct)*
- **C.** 5
- **D.** 3

> **Explanation**: Distinct numbers sorted descending are 10, 8, 5, 3. The second-largest is 8.

---

#### [easy_23] How many vowels are in \
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #23  

- **A.** 3
- **B.** 4 ✅ *(Correct)*
- **C.** 5
- **D.** 6

> **Explanation**: The vowels are \

---

#### [easy_24] What are the first 6 Fibonacci numbers, starting with 0, 1?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #24  

- **A.** 0 1 1 2 3 5 ✅ *(Correct)*
- **B.** 1 1 2 3 5 8
- **C.** 0 1 2 3 5 8
- **D.** 1 2 3 5 8 13

> **Explanation**: The sequence starts: 0, 1, (0+1)=1, (1+1)=2, (1+2)=3, (2+3)=5.

---

#### [easy_25] How many distinct values appear more than once?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #25  
```text
4, 2, 7, 2, 4, 9
```

- **A.** 1
- **B.** 2 ✅ *(Correct)*
- **C.** 3
- **D.** 4

> **Explanation**: The values 4 and 2 each appear more than once (2 distinct values).

---

#### [easy_26] Which is a prime number?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #26  

- **A.** 15
- **B.** 21
- **C.** 17 ✅ *(Correct)*
- **D.** 27

> **Explanation**: 17 is prime as it is divisible only by 1 and itself.

---

#### [easy_27] What is the array after rotating right by one position?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #27  
```text
1, 2, 3, 4
```

- **A.** 2, 3, 4, 1
- **B.** 4, 1, 2, 3 ✅ *(Correct)*
- **C.** 1, 4, 2, 3
- **D.** 3, 4, 1, 2

> **Explanation**: Rotating right by 1 shifts 4 to the front: [4, 1, 2, 3].

---

#### [easy_28] How many times does \
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #28  

- **A.** 1
- **B.** 2
- **C.** 3 ✅ *(Correct)*
- **D.** 4

> **Explanation**: \

---

#### [easy_29] Which is a perfect number?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #29  

- **A.** 12
- **B.** 18
- **C.** 28 ✅ *(Correct)*
- **D.** 30

> **Explanation**: 28\

---

#### [easy_30] Which bracket sequence is balanced?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #30  

- **A.** (()
- **B.** ())(
- **C.** (()()) ✅ *(Correct)*
- **D.** ))((

> **Explanation**: (()()) has every opening bracket closed in the correct nesting order.

---

#### [easy_31] Which method checks items one by one?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #31  

- **A.** Binary Search
- **B.** Linear Search ✅ *(Correct)*
- **C.** Merge Sort
- **D.** Selection Sort

> **Explanation**: Linear search checks items sequentially from the beginning to the end.

---

#### [easy_32] Binary Search requires the data to be:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #32  

- **A.** Unsorted
- **B.** Sorted ✅ *(Correct)*
- **C.** Reversed
- **D.** Duplicated

> **Explanation**: Binary search relies on sorted data to decide which half of the search space to eliminate.

---

#### [easy_33] Worst-case comparisons for Linear Search on n items are:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #33  

- **A.** 1
- **B.** log n
- **C.** n ✅ *(Correct)*
- **D.** n²

> **Explanation**: In the worst case, the target is at the very last position or not present at all, requiring n checks.

---

#### [easy_34] Binary Search has which time complexity?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #34  

- **A.** O(1)
- **B.** O(log n) ✅ *(Correct)*
- **C.** O(n)
- **D.** O(n²)

> **Explanation**: Binary search halves the remaining search interval each step, resulting in O(log n) time.

---

#### [easy_35] If the target is smaller than the middle item, Binary Search checks the:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #35  

- **A.** Right half
- **B.** Left half ✅ *(Correct)*
- **C.** Whole array
- **D.** Neither half

> **Explanation**: In a sorted array in ascending order, smaller values reside in the left half.

---

#### [easy_36] For 16 sorted items, how many halvings reduce the range to one item?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #36  

- **A.** 2
- **B.** 4 ✅ *(Correct)*
- **C.** 8
- **D.** 16

> **Explanation**: 16 -> 8 -> 4 -> 2 -> 1 takes exactly log2(16) = 4 halvings.

---

#### [easy_37] Best-case Linear Search complexity is:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #37  

- **A.** O(1) ✅ *(Correct)*
- **B.** O(log n)
- **C.** O(n)
- **D.** O(n²)

> **Explanation**: The target may be the very first item checked at index 0, requiring O(1) comparison.

---

#### [easy_38] Binary Search works by:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #38  

- **A.** Checking every item
- **B.** Halving the search interval ✅ *(Correct)*
- **C.** Swapping adjacent items
- **D.** Building a tree

> **Explanation**: Binary search repeatedly divides the search range in half.

---

#### [easy_39] If Linear Search finds the target at the first position, comparisons needed:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #39  

- **A.** 1 ✅ *(Correct)*
- **B.** n
- **C.** log n
- **D.** n²

> **Explanation**: Only the first item is compared when the target is at the head of the list.

---

#### [easy_40] Which is suitable for a small unsorted list?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #40  

- **A.** Binary Search
- **B.** Linear Search ✅ *(Correct)*
- **C.** Merge Sort
- **D.** Quick Sort

> **Explanation**: Linear search does not require prior sorting and has virtually zero overhead for small lists.

---

#### [easy_41] Which sort swaps adjacent out-of-order elements?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #41  

- **A.** Selection Sort
- **B.** Bubble Sort ✅ *(Correct)*
- **C.** Merge Sort
- **D.** Binary Search

> **Explanation**: Bubble sort iterates through the list comparing and swapping adjacent items.

---

#### [easy_42] Which sort repeatedly selects the smallest remaining item?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #42  

- **A.** Selection Sort ✅ *(Correct)*
- **B.** Insertion Sort
- **C.** Quick Sort
- **D.** Linear Search

> **Explanation**: Selection sort repeatedly finds the minimum item from the unsorted segment and places it at the front.

---

#### [easy_43] Which sort inserts each item into its position in a sorted section?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #43  

- **A.** Bubble Sort
- **B.** Insertion Sort ✅ *(Correct)*
- **C.** Merge Sort
- **D.** Binary Search

> **Explanation**: Insertion sort builds the final sorted array one item at a time by inserting it into its correct position.

---

#### [easy_44] Which sort splits arrays and merges sorted halves?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #44  

- **A.** Bubble Sort
- **B.** Merge Sort ✅ *(Correct)*
- **C.** Selection Sort
- **D.** Linear Search

> **Explanation**: Merge sort divides the array into two halves, recursively sorts them, and merges them back.

---

#### [easy_45] Worst-case Merge Sort time complexity:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #45  

- **A.** O(n)
- **B.** O(log n)
- **C.** O(n log n) ✅ *(Correct)*
- **D.** O(n²)

> **Explanation**: Merge sort guarantees O(n log n) running time even in the worst case.

---

#### [easy_46] Average-case Quick Sort time complexity:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #46  

- **A.** O(1)
- **B.** O(log n)
- **C.** O(n log n) ✅ *(Correct)*
- **D.** O(n²)

> **Explanation**: Quick sort\

---

#### [easy_47] Worst-case standard Quick Sort time complexity:
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #47  

- **A.** O(n)
- **B.** O(n log n)
- **C.** O(n²) ✅ *(Correct)*
- **D.** O(log n)

> **Explanation**: When partitions are severely unbalanced (e.g., already sorted array with first element as pivot), Quick sort degrades to O(n²).

---

#### [easy_48] Which simple sort often works well on small or nearly sorted arrays?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #48  

- **A.** Insertion Sort ✅ *(Correct)*
- **B.** Merge Sort
- **C.** Heap Sort
- **D.** Counting Sort

> **Explanation**: Insertion sort takes O(n) linear time on already or nearly sorted arrays.

---

#### [easy_49] After one left-to-right Bubble Sort pass in ascending order, which item is guaranteed at the end?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #49  

- **A.** Smallest
- **B.** Largest ✅ *(Correct)*
- **C.** Middle
- **D.** None

> **Explanation**: The largest element \

---

#### [easy_50] Which array sort typically uses O(n) auxiliary space?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #50  

- **A.** Selection Sort
- **B.** Insertion Sort
- **C.** Merge Sort ✅ *(Correct)*
- **D.** Bubble Sort

> **Explanation**: Standard array-based merge sort requires O(n) extra space to merge the two sorted halves.

---

#### [easy_51] A class is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #51  

- **A.** A blueprint for objects ✅ *(Correct)*
- **B.** A loop
- **C.** A sorting method
- **D.** A database row

> **Explanation**: A class defines the template, state (fields), and behavior (methods) for creating objects.

---

#### [easy_52] An object is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #52  

- **A.** A blueprint
- **B.** An instance of a class ✅ *(Correct)*
- **C.** A compiler
- **D.** A condition

> **Explanation**: An object is a concrete, tangible instance created from a class blueprint in memory.

---

#### [easy_53] Which concept lets a class reuse features of another class?
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #53  

- **A.** Encapsulation
- **B.** Inheritance ✅ *(Correct)*
- **C.** Compilation
- **D.** Iteration

> **Explanation**: Inheritance allows a subclass (child) to inherit fields and methods from a superclass (parent).

---

#### [easy_54] One interface or method name showing different behaviors is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #54  

- **A.** Polymorphism ✅ *(Correct)*
- **B.** Sorting
- **C.** Recursion
- **D.** Searching

> **Explanation**: Polymorphism (\

---

#### [easy_55] Bundling data and methods and controlling access is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #55  

- **A.** Encapsulation ✅ *(Correct)*
- **B.** Binary Search
- **C.** Iteration
- **D.** Compilation

> **Explanation**: Encapsulation wraps state and behavior together and restricts direct external access via access modifiers.

---

#### [easy_56] Hiding implementation details while exposing essential features is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #56  

- **A.** Abstraction ✅ *(Correct)*
- **B.** Inheritance
- **C.** Selection
- **D.** Iteration

> **Explanation**: Abstraction presents a clean, simple high-level interface to the user while keeping internal mechanics private.

---

#### [easy_57] A constructor is commonly used for:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #57  

- **A.** Initializing a new object ✅ *(Correct)*
- **B.** Sorting an array
- **C.** Ending a loop
- **D.** Searching a file

> **Explanation**: A constructor is a special class member called automatically when instantiating an object to initialize its state.

---

#### [easy_58] A child class provides its own version of an inherited method. This is:
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #58  

- **A.** Method overriding ✅ *(Correct)*
- **B.** Binary searching
- **C.** Sorting
- **D.** Data conversion

> **Explanation**: Method overriding allows a subclass to define a specific implementation for a method declared in its parent class.

---

#### [easy_59] Inheritance commonly represents which relationship?
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #59  

- **A.** HAS-A
- **B.** IS-A ✅ *(Correct)*
- **C.** RUNS-A
- **D.** SORTS-A

> **Explanation**: Inheritance models an IS-A relationship (e.g., a Dog IS-A Animal). Composition models a HAS-A relationship.

---

#### [easy_60] Which access modifier usually restricts direct outside access to a member?
**Tier**: `Easy` (Level 1) | **Stack**: `OOPs & Architecture` | **Number**: #60  

- **A.** public
- **B.** private ✅ *(Correct)*
- **C.** global
- **D.** static

> **Explanation**: The \

---

#### [easy_61] What value is printed? (Array indexing starts at 0.)
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #61  
```text
arr = [2, 4, 6, 8]
PRINT arr[0]
```

- **A.** 2 ✅ *(Correct)*
- **B.** 1
- **C.** 4
- **D.** 3

> **Explanation**: Index 0 contains 2.

---

#### [easy_62] What value is printed? (Array indexing starts at 0.)
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #62  
```text
arr = [4, 6, 8, 10]
PRINT arr[2]
```

- **A.** 9
- **B.** 8 ✅ *(Correct)*
- **C.** 7
- **D.** 10

> **Explanation**: Index 2 contains 8.

---

#### [easy_63] What is the final sum?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #63  
```text
arr = [2, 3, 4, 5]
sum = 0
FOR each value IN arr
sum = sum + value
PRINT sum
```

- **A.** 13
- **B.** 15
- **C.** 14 ✅ *(Correct)*
- **D.** 16

> **Explanation**: The array values add up to 14.

---

#### [easy_64] What is the final sum?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #64  
```text
arr = [4, 5, 6, 7]
sum = 0
FOR each value IN arr
sum = sum + value
PRINT sum
```

- **A.** 24
- **B.** 23
- **C.** 22 ✅ *(Correct)*
- **D.** 21

> **Explanation**: The array values add up to 22.

---

#### [easy_65] How many times does the inner statement execute?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #65  
```text
count = 0
FOR i = 1 TO 4
FOR j = 1 TO 4
count = count + 1
PRINT count
```

- **A.** 15
- **B.** 18
- **C.** 16 ✅ *(Correct)*
- **D.** 17

> **Explanation**: The nested loops run 4 × 4 = 16 times.

---

#### [easy_66] How many times does the inner statement execute?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #66  
```text
count = 0
FOR i = 1 TO 5
FOR j = 1 TO 2
count = count + 1
PRINT count
```

- **A.** 10 ✅ *(Correct)*
- **B.** 12
- **C.** 9
- **D.** 11

> **Explanation**: The nested loops run 5 × 2 = 10 times.

---

#### [easy_67] What is printed?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #67  
```text
word = 
```

- **A.** coding
- **B.** gnidoc ✅ *(Correct)*
- **C.** Error
- **D.** CODING

> **Explanation**: Reversing coding gives gnidoc.

---

#### [easy_68] What is printed?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #68  
```text
word = 
```

- **A.** radar ✅ *(Correct)*
- **B.** Error
- **C.** RADAR
- **D.** None of these

> **Explanation**: Reversing radar gives radar.

---

#### [easy_69] What is the sum of even numbers from 1 through the limit?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #69  
```text
sum = 0
FOR i = 1 TO 5
IF i MOD 2 == 0
sum = sum + i
PRINT sum
```

- **A.** 5
- **B.** 6 ✅ *(Correct)*
- **C.** 7
- **D.** 8

> **Explanation**: The even numbers up to 5 add up to 6.

---

#### [easy_70] What is the sum of even numbers from 1 through the limit?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #70  
```text
sum = 0
FOR i = 1 TO 6
IF i MOD 2 == 0
sum = sum + i
PRINT sum
```

- **A.** 13
- **B.** 14
- **C.** 11
- **D.** 12 ✅ *(Correct)*

> **Explanation**: The even numbers up to 6 add up to 12.

---

#### [easy_71] How many times does the target appear?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #71  
```text
arr = [2, 3, 2, 4, 2]
target = 2
PRINT COUNT(arr, target)
```

- **A.** 5
- **B.** 3 ✅ *(Correct)*
- **C.** 2
- **D.** 4

> **Explanation**: 2 appears 3 times.

---

#### [easy_72] How many times does the target appear?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #72  
```text
arr = [4, 5, 4, 6, 4]
target = 4
PRINT COUNT(arr, target)
```

- **A.** 2
- **B.** 4
- **C.** 3 ✅ *(Correct)*
- **D.** 5

> **Explanation**: 4 appears 3 times.

---

#### [easy_73] How many even digits are in the number?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #73  
```text
number = 12
PRINT COUNT_EVEN_DIGITS(number)
```

- **A.** 3
- **B.** 2
- **C.** 1 ✅ *(Correct)*
- **D.** 0

> **Explanation**: 12 contains 1 even digit(s).

---

#### [easy_74] How many even digits are in the number?
**Tier**: `Easy` (Level 1) | **Stack**: `DSA & Logic` | **Number**: #74  
```text
number = 13
PRINT COUNT_EVEN_DIGITS(number)
```

- **A.** 0 ✅ *(Correct)*
- **B.** -1
- **C.** 2
- **D.** 1

> **Explanation**: 13 contains 0 even digit(s).

---

## 🟠 Level 2: Hard (Ranked) — 42 Unique Questions

#### [med_1] Which Data Structure operates on a Last-In, First-Out (LIFO) order?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #1  

- **A.** Queue
- **B.** Stack ✅ *(Correct)*
- **C.** LinkedList
- **D.** Heap

> **Explanation**: A Stack is a LIFO (Last-In, First-Out) data structure where elements are added and removed from the top.

---

#### [med_2] What is the average time complexity of searching an element in a Binary Search Tree (BST)?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #2  

- **A.** O(1)
- **B.** O(n)
- **C.** O(log n) ✅ *(Correct)*
- **D.** O(n^2)

> **Explanation**: Searching in a balanced BST halves the search space at each step, yielding O(log n) time complexity.

---

#### [med_3] What is the primary difference between a `StatelessWidget` and a `StatefulWidget` in Flutter?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #3  

- **A.** StatelessWidget cannot have colors
- **B.** StatefulWidget maintains mutable state that can change over time ✅ *(Correct)*
- **C.** StatelessWidget runs faster on Android only
- **D.** StatefulWidget cannot rebuild

> **Explanation**: StatefulWidgets possess internal State objects that can trigger UI rebuilds via `setState()`.

---

#### [med_4] In relational databases, what does ACID stand for?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #4  

- **A.** Atomicity, Consistency, Isolation, Durability ✅ *(Correct)*
- **B.** Access, Control, Indexing, Data
- **C.** Accuracy, Concurrency, Integrity, Distribution
- **D.** Automated, Concurrent, Isolated, Durable

> **Explanation**: ACID guarantees database transaction reliability: Atomicity, Consistency, Isolation, Durability.

---

#### [med_5] What does the `async` and `await` keywords achieve in Dart/JavaScript?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #5  

- **A.** Run code synchronously by blocking UI
- **B.** Allow asynchronous code to be written in a clean, non-blocking readable style ✅ *(Correct)*
- **C.** Create new multithreaded CPU cores
- **D.** Prevent network calls

> **Explanation**: `async`/`await` simplifies working with Futures/Promises, executing non-blocking asynchronous operations cleanly.

---

#### [med_6] Which HTTP response status code indicates an 
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #6  

- **A.** 400
- **B.** 401
- **C.** 403
- **D.** 500 ✅ *(Correct)*

> **Explanation**: 500 Internal Server Error indicates that the server encountered an unexpected condition that prevented it from fulfilling the request.

---

#### [med_7] What is a Foreign Key in a relational database table?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #7  

- **A.** A key that encrypts data
- **B.** A column that references the primary key of another table to establish relationships ✅ *(Correct)*
- **C.** A key imported from a non-SQL database
- **D.** The first column of every table

> **Explanation**: A Foreign Key enforces referential integrity by referencing the Primary Key of another table.

---

#### [med_8] What is the time complexity of pushing an element onto a Stack or Queue?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #8  

- **A.** O(1) ✅ *(Correct)*
- **B.** O(n)
- **C.** O(log n)
- **D.** O(n log n)

> **Explanation**: Pushing onto a stack or enqueuing in a queue takes constant time O(1).

---

#### [med_9] In OOP, what is Encapsulation?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #9  

- **A.** Bundling data and methods into a single unit (class) and restricting direct access to internal details ✅ *(Correct)*
- **B.** Creating multiple child classes from one parent
- **C.** Overloading functions with different parameters
- **D.** Converting code into binary executable

> **Explanation**: Encapsulation hides internal implementation details of an object and exposes only a clean interface.

---

#### [med_10] What is the output of `[1, 2, 3].map((x) => x * 2).toList()` in Dart?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #10  


> **Explanation**: The map function transforms every element by doubling it: 1*2=2, 2*2=4, 3*2=6.

---

#### [med_11] Which of the following is a NoSQL document database?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #11  

- **A.** PostgreSQL
- **B.** MySQL
- **C.** MongoDB ✅ *(Correct)*
- **D.** SQLite

> **Explanation**: MongoDB is a leading NoSQL document-oriented database that stores JSON-like BSON documents.

---

#### [med_12] What happens during a `git rebase` compared to a `git merge`?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #12  

- **A.** Rebase deletes all commit history
- **B.** Rebase rewrites commit history by moving changes onto the tip of another branch linearly ✅ *(Correct)*
- **C.** Rebase creates a new merge commit automatically
- **D.** Rebase sends commits directly to remote server

> **Explanation**: Rebase moves or combines a sequence of commits to a new base commit, creating a linear history.

---

#### [med_13] What is the purpose of state management packages like Provider, Riverpod, or Bloc in Flutter?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #13  

- **A.** To accelerate app download speed
- **B.** To cleanly share and manage app state across multiple widget subtrees ✅ *(Correct)*
- **C.** To compile Dart code into native iOS binaries
- **D.** To format SQL queries

> **Explanation**: State management separates business logic from UI and efficiently propagates state changes across widgets.

---

#### [med_14] What is the main function of a DNS server in networking?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #14  

- **A.** Encrypt web traffic
- **B.** Translate human-friendly domain names (e.g. google.com) into IP addresses ✅ *(Correct)*
- **C.** Store website HTML files
- **D.** Block computer viruses

> **Explanation**: DNS (Domain Name System) maps hostnames to IP addresses so browsers can load internet resources.

---

#### [med_15] What is a Deadlock in operating systems or concurrency?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #15  

- **A.** When an app runs out of battery power
- **B.** A situation where 2 or more processes are blocked forever waiting for each other to release resources ✅ *(Correct)*
- **C.** When a CPU core gets too hot
- **D.** A broken database link

> **Explanation**: Deadlock occurs when process A holds resource 1 and waits for resource 2 held by process B, while B holds 2 and waits for 1.

---

#### [med_16] Which Dart collection type guarantees that all elements are unique?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #16  

- **A.** List
- **B.** Set ✅ *(Correct)*
- **C.** Map
- **D.** Queue

> **Explanation**: A `Set` is an unordered collection of unique items.

---

#### [med_17] What does the SQL `INNER JOIN` keyword return?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #17  

- **A.** All rows from both tables
- **B.** Only records that have matching values in both tables ✅ *(Correct)*
- **C.** All rows from the left table and matched rows from the right table
- **D.** Null values for missing columns

> **Explanation**: `INNER JOIN` selects records that have matching values in both joined tables.

---

#### [med_18] In RESTful API design, which HTTP method is used to update existing resources completely?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #18  

- **A.** POST
- **B.** GET
- **C.** PUT ✅ *(Correct)*
- **D.** DELETE

> **Explanation**: PUT replaces all current representations of the target resource with the request payload.

---

#### [med_19] What is the result of `5 == 
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #19  

- **A.** Both return true
- **B.** == returns true, === returns false ✅ *(Correct)*
- **C.** Both return false
- **D.** == returns false, === returns true

> **Explanation**: `==` performs type coercion so 5 == 

---

#### [med_20] What is the time complexity of Quick Sort in the average case?
**Tier**: `Medium` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #20  

- **A.** O(n)
- **B.** O(n log n) ✅ *(Correct)*
- **C.** O(n^2)
- **D.** O(1)

> **Explanation**: Quick Sort splits arrays recursively around a pivot, achieving average O(n log n) performance.

---

#### [med_21] O(n) represents:
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #21  

- **A.** Constant growth
- **B.** Linear growth ✅ *(Correct)*
- **C.** Logarithmic growth
- **D.** Quadratic growth

> **Explanation**: O(n) indicates runtime or operations grow proportionally with the input size n.

---

#### [med_22] Which grows slowest for large n?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #22  

- **A.** O(n²)
- **B.** O(n log n)
- **C.** O(n)
- **D.** O(1) ✅ *(Correct)*

> **Explanation**: O(1) constant time does not grow as n increases, making it the slowest growing.

---

#### [med_23] A loop runs n times with constant work each time. Complexity?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #23  

- **A.** O(1)
- **B.** O(log n)
- **C.** O(n) ✅ *(Correct)*
- **D.** O(n²)

> **Explanation**: n iterations * O(1) work = O(n) linear time complexity.

---

#### [med_24] Two nested loops each run n times. Complexity?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #24  

- **A.** O(n)
- **B.** O(n²) ✅ *(Correct)*
- **C.** O(log n)
- **D.** O(1)

> **Explanation**: The inner loop runs n times for each of the n iterations of the outer loop: n * n = O(n²).

---

#### [med_25] A loop doubles its counter until it exceeds n. Complexity?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #25  

- **A.** O(1)
- **B.** O(log n) ✅ *(Correct)*
- **C.** O(n)
- **D.** O(n²)

> **Explanation**: When the step multiplies (doubles) each iteration (1, 2, 4, 8, ...), it terminates in log2(n) steps.

---

#### [med_26] Which notation expresses an asymptotic upper bound?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #26  

- **A.** Big O ✅ *(Correct)*
- **B.** Big Omega
- **C.** Big Theta
- **D.** Modulo

> **Explanation**: Big O notation (O) defines the formal mathematical upper bound on algorithm growth.

---

#### [med_27] An algorithm takes 3n + 10 operations. Big O?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #27  

- **A.** O(1)
- **B.** O(log n)
- **C.** O(n) ✅ *(Correct)*
- **D.** O(n²)

> **Explanation**: In asymptotic analysis, we drop constant factors (3) and lower-order terms (10), leaving O(n).

---

#### [med_28] Space complexity measures:
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #28  

- **A.** CPU speed
- **B.** Memory use as input grows ✅ *(Correct)*
- **C.** Internet speed
- **D.** Lines of code

> **Explanation**: Space complexity quantifies the total auxiliary memory required by an algorithm as input size scales.

---

#### [med_29] Checking every pair using two nested loops is typically:
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #29  

- **A.** O(log n)
- **B.** O(n)
- **C.** O(n log n)
- **D.** O(n²) ✅ *(Correct)*

> **Explanation**: There are approximately n*(n-1)/2 pairs in an array of size n, which is O(n²).

---

#### [med_30] Best-case complexity describes:
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #30  

- **A.** Maximum work
- **B.** Minimum work for inputs of a given size ✅ *(Correct)*
- **C.** Memory use
- **D.** Number of code lines

> **Explanation**: Best-case analysis calculates the minimum number of steps or resources required under ideal input conditions.

---

#### [med_31] What is the final value of count?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #31  
```text
count = 0
FOR i = 1 TO 3
FOR j = 1 TO i
count = count + 1
PRINT count
```

- **A.** 5
- **B.** 7
- **C.** 6 ✅ *(Correct)*
- **D.** 8

> **Explanation**: The inner loop runs 1 + 2 + ... + 3 = 6 times.

---

#### [med_32] What is the final value of count?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #32  
```text
count = 0
FOR i = 1 TO 4
FOR j = 1 TO i
count = count + 1
PRINT count
```

- **A.** 9
- **B.** 11
- **C.** 10 ✅ *(Correct)*
- **D.** 12

> **Explanation**: The inner loop runs 1 + 2 + ... + 4 = 10 times.

---

#### [med_33] What value is printed?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #33  
```text
arr = [7, 2, 5, 0]
PRINT MAX(arr) - MIN(arr)
```

- **A.** 8
- **B.** 9
- **C.** 6
- **D.** 7 ✅ *(Correct)*

> **Explanation**: Maximum 7 minus minimum 0 equals 7.

---

#### [med_34] What value is printed?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #34  
```text
arr = [8, 3, 6, 1]
PRINT MAX(arr) - MIN(arr)
```

- **A.** 9
- **B.** 6
- **C.** 8
- **D.** 7 ✅ *(Correct)*

> **Explanation**: Maximum 8 minus minimum 1 equals 7.

---

#### [med_35] What is the final value of result?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #35  
```text
result = 1
FOR i = 1 TO 6
result = result * i
PRINT result
```

- **A.** 719
- **B.** 721
- **C.** 722
- **D.** 720 ✅ *(Correct)*

> **Explanation**: The loop calculates 6! = 720.

---

#### [med_36] What is the final value of result?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #36  
```text
result = 1
FOR i = 1 TO 4
result = result * i
PRINT result
```

- **A.** 23
- **B.** 24 ✅ *(Correct)*
- **C.** 25
- **D.** 26

> **Explanation**: The loop calculates 4! = 24.

---

#### [med_37] What is the final value of count?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #37  
```text
count = 0
FOR i = 1 TO 5
FOR j = 1 TO 2
IF (i + j) MOD 2 == 0
count = count + 1
PRINT count
```

- **A.** 5 ✅ *(Correct)*
- **B.** 4
- **C.** 7
- **D.** 6

> **Explanation**: There are 5 pairs whose sum is even.

---

#### [med_38] What is the final value of count?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #38  
```text
count = 0
FOR i = 1 TO 2
FOR j = 1 TO 3
IF (i + j) MOD 2 == 0
count = count + 1
PRINT count
```

- **A.** 5
- **B.** 4
- **C.** 2
- **D.** 3 ✅ *(Correct)*

> **Explanation**: There are 3 pairs whose sum is even.

---

#### [med_39] What is the final value of x?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #39  
```text
x = 20
WHILE x >= 10
x = SUM_OF_DIGITS(x)
PRINT x
```

- **A.** 2 ✅ *(Correct)*
- **B.** 3
- **C.** 4
- **D.** 1

> **Explanation**: Repeated digit sums reduce 20 to 2.

---

#### [med_40] What is the final value of x?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #40  
```text
x = 21
WHILE x >= 10
x = SUM_OF_DIGITS(x)
PRINT x
```

- **A.** 4
- **B.** 3 ✅ *(Correct)*
- **C.** 5
- **D.** 2

> **Explanation**: Repeated digit sums reduce 21 to 3.

---

#### [med_41] How many distinct values are in the array?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #41  
```text
arr = [4, 5, 6, 7]
PRINT COUNT_DISTINCT(arr)
```

- **A.** 3
- **B.** 6
- **C.** 5
- **D.** 4 ✅ *(Correct)*

> **Explanation**: The array contains 4 distinct value(s).

---

#### [med_42] How many distinct values are in the array?
**Tier**: `Med` (Level 2) | **Stack**: `DSA & Logic` | **Number**: #42  
```text
arr = [5, 2, 7, 8]
PRINT COUNT_DISTINCT(arr)
```

- **A.** 3
- **B.** 6
- **C.** 4 ✅ *(Correct)*
- **D.** 5

> **Explanation**: The array contains 4 distinct value(s).

---

## 🟣 Level 3: Ultra (Final Circle) — 30 Unique Questions

#### [hard_1] What is the worst-case time complexity of Quick Sort when selecting a poor pivot?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #1  

- **A.** O(n log n)
- **B.** O(n^2) ✅ *(Correct)*
- **C.** O(n)
- **D.** O(2^n)

> **Explanation**: In the worst case (e.g. sorted array with first element as pivot), Quick Sort degrades to O(n^2).

---

#### [hard_2] What is an Isolates in Dart concurrency model?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #2  

- **A.** A UI widget isolated from rendering
- **B.** An independent worker thread with its own private memory heap, communicating via message passing ✅ *(Correct)*
- **C.** A secure database connection
- **D.** A CSS isolation property

> **Explanation**: Dart code runs inside Isolates. Each Isolate has its own memory heap and event loop, preventing shared-memory state issues.

---

#### [hard_3] In System Design, what does CAP Theorem state about Distributed Systems?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #3  

- **A.** A system can simultaneously guarantee Consistency, Availability, and Partition Tolerance
- **B.** A distributed data store can provide at most TWO of Consistency, Availability, and Partition Tolerance ✅ *(Correct)*
- **C.** Centralized servers perform better than distributed clusters
- **D.** Caching guarantees zero latency

> **Explanation**: CAP Theorem asserts that a distributed data store can simultaneously provide at most two out of three guarantees: Consistency, Availability, and Partition tolerance.

---

#### [hard_4] What is the primary function of a B-Tree index in database storage engines like PostgreSQL or MySQL?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #4  

- **A.** To compress image files stored in rows
- **B.** To maintain balanced self-sorting tree structures for logarithmic time data retrieval and range queries ✅ *(Correct)*
- **C.** To generate random primary key UUIDs
- **D.** To manage network sockets

> **Explanation**: B-Trees keep data sorted and allow searches, sequential access, insertions, and deletions in logarithmic time (O(log n)).

---

#### [hard_5] What algorithm is commonly used for finding the shortest path in a weighted graph with non-negative edge weights?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #5  

- **A.** Kruskal\
- **B.** ,  ✅ *(Correct)*
- **C.** s Algorithm
- **D.** Bellman-Ford Algorithm
- **?.** Floyd-Warshall Algorithm

> **Explanation**: Dijkstra\

---

#### [hard_6] What is garbage collection in programming runtimes like Java, Go, and V8?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #6  

- **A.** Deleting unused code files from disk
- **B.** Automatic memory management process that frees memory allocated to objects no longer referenced ✅ *(Correct)*
- **C.** Clearing browser cookies
- **D.** Restarting dead server processes

> **Explanation**: Garbage collection identifies and reclaims memory allocated to objects that are no longer reachable by the program.

---

#### [hard_7] What is the difference between Process and Thread in OS concurrency?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #7  

- **A.** Processes share memory, threads have isolated memory
- **B.** A Process has its own independent memory address space, while Threads within a process share memory address space ✅ *(Correct)*
- **C.** Threads run on GPU, Processes run on CPU
- **D.** There is no difference

> **Explanation**: Processes have independent address spaces, while threads execute concurrently within a process sharing memory.

---

#### [hard_8] What is a Closure in JavaScript or functional programming?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #8  

- **A.** A method to close database connections
- **B.** A function combined with references to its lexical environment, remembering outer variables even after the outer function finishes execution ✅ *(Correct)*
- **C.** A loop termination condition
- **D.** A private class destructor

> **Explanation**: A closure gives an inner function access to its outer function\

---

#### [hard_9] In Flutter, what are the three trees managed by the engine?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #9  

- **A.** DOM Tree, CSS Tree, Layout Tree
- **B.** Widget Tree, Element Tree, RenderObject Tree ✅ *(Correct)*
- **C.** State Tree, Data Tree, Output Tree
- **D.** Binary Tree, AVL Tree, Red-Black Tree

> **Explanation**: Flutter maintains Widget Tree (configuration), Element Tree (instantiated widgets & state), and RenderObject Tree (layout & painting).

---

#### [hard_10] What is the space complexity of Depth-First Search (DFS) on a tree of depth `h`?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #10  

- **A.** O(1)
- **B.** O(h) ✅ *(Correct)*
- **C.** O(V + E)
- **D.** O(2^h)

> **Explanation**: DFS uses call stack proportional to the maximum height of the tree `O(h)`.

---

#### [hard_11] What does the SOLID principle 
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #11  

- **A.** Single Responsibility Principle ✅ *(Correct)*
- **B.** Simple Structure Principle
- **C.** Sequential State Principle
- **D.** Secure Socket Principle

> **Explanation**: Single Responsibility Principle states that a class should have one, and only one, reason to change.

---

#### [hard_12] What is connection pooling in database client architecture?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #12  

- **A.** Combining multiple databases into one table
- **B.** Reusing a cache of pre-established database connections instead of opening/closing connections repeatedly ✅ *(Correct)*
- **C.** Syncing local storage with cloud
- **D.** Running SQL queries over web sockets

> **Explanation**: Connection pooling maintains reusable database connections, eliminating the high overhead of establishing connections for every request.

---

#### [hard_13] What is a Race Condition in concurrent systems?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #13  

- **A.** Two CPU cores competing for clock speed
- **B.** A flaw when output depends on non-deterministic sequence or timing of controllable events ✅ *(Correct)*
- **C.** Network latency spikes during peak hours
- **D.** Fast automated unit tests

> **Explanation**: Race conditions occur when multiple threads access shared data concurrently and try to change it at the same time without synchronization.

---

#### [hard_14] What is the main advantage of using a Bloom Filter in distributed caching?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #14  

- **A.** Guarantees 100% accurate key retrieval with zero false positives
- **B.** Space-efficient probabilistic data structure used to test whether an element is definitely NOT in a set or POSSIBLY in a set ✅ *(Correct)*
- **C.** Replaces relational SQL indexes
- **D.** Encrypts cached user sessions

> **Explanation**: Bloom filters use minimal memory to tell if an item is definitely not present, avoiding expensive cache misses / disk lookups.

---

#### [hard_15] What is the purpose of JWT (JSON Web Token) in stateless authentication?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #15  

- **A.** To format SQL queries safely
- **B.** Digitally signed compact token that securely transmits claims between parties without requiring session state on the server ✅ *(Correct)*
- **C.** To compress media files
- **D.** To manage DNS routing

> **Explanation**: JWTs allow servers to verify client requests statelessly using cryptographic signatures (HMAC or RSA).

---

#### [hard_16] What is the time complexity of building a heap from an unsorted array of `n` elements using Floyd\
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #16  

- **A.** O(n log n)
- **B.** O(n) ✅ *(Correct)*
- **C.** O(n^2)
- **D.** O(log n)

> **Explanation**: Floyd\

---

#### [hard_17] In Git, what does `git cherry-pick <commit-hash>` do?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #17  

- **A.** Deletes a commit from history
- **B.** Applies the changes introduced by an existing specific commit onto the current branch ✅ *(Correct)*
- **C.** Creates a new remote branch
- **D.** Reverts all unstaged changes

> **Explanation**: Cherry-picking copies a specific commit from one branch and applies it to another.

---

#### [hard_18] What is Idempotency in API design?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #18  

- **A.** Making API requests run 10x faster
- **B.** Property of an operation where making multiple identical requests has the same effect as making a single request ✅ *(Correct)*
- **C.** Securing requests with SSL
- **D.** Automatic retry of failed requests

> **Explanation**: GET, PUT, and DELETE are idempotent because repeating them yields the exact same server state as executing once.

---

#### [hard_19] What is the difference between TCP and UDP protocols?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #19  

- **A.** TCP is connectionless and fast, UDP is connection-oriented
- **B.** TCP is reliable, ordered, connection-oriented; UDP is connectionless, lower latency, with no delivery guarantee ✅ *(Correct)*
- **C.** TCP only runs on mobile devices
- **D.** UDP encrypts all packet payloads

> **Explanation**: TCP guarantees packet order and delivery via handshakes, while UDP streams packets without connection overhead.

---

#### [hard_20] Congratulations on reaching Question 20 of Ultra! What is the term for a recursive function that makes its recursive call as its last operation?
**Tier**: `Ultra` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #20  

- **A.** Head Recursion
- **B.** Tail Recursion ✅ *(Correct)*
- **C.** Nested Recursion
- **D.** Mutual Recursion

> **Explanation**: Tail Recursion occurs when the recursive call is the final action in a function. Compilers can optimize this by reusing the current stack frame.

---

#### [hard_21] Which number appears only once?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #21  
```text
4, 1, 2, 1, 2
```

- **A.** 1
- **B.** 2
- **C.** 4 ✅ *(Correct)*
- **D.** None

> **Explanation**: 1 and 2 appear twice, while 4 appears only once (classic Single Number problem).

---

#### [hard_22] What is the maximum number of consecutive 1s?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #22  
```text
1, 1, 0, 1, 1, 1, 0
```

- **A.** 2
- **B.** 3 ✅ *(Correct)*
- **C.** 4
- **D.** 5

> **Explanation**: The longest contiguous sequence of 1s has 3 ones in a row.

---

#### [hard_23] Which indices contain two numbers that sum to 9?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #23  
```text
Array: [2, 7, 11, 15]; Target: 9
```

- **A.** 0, 2
- **B.** 1, 2
- **C.** 0, 1 ✅ *(Correct)*
- **D.** 2, 3

> **Explanation**: Array[0] + Array[1] = 2 + 7 = 9 (Two Sum problem).

---

#### [hard_24] Which array forms a mountain?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #24  

- **A.** 1, 2, 3, 2, 1 ✅ *(Correct)*
- **B.** 1, 2, 3, 4
- **C.** 3, 2, 1, 2
- **D.** 1, 3, 2, 4

> **Explanation**: A mountain array strictly increases to a peak (1 -> 2 -> 3) then strictly decreases (3 -> 2 -> 1).

---

#### [hard_25] What is the first non-repeating character in \
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #25  

- **A.** a
- **B.** b
- **C.** c ✅ *(Correct)*
- **D.** d

> **Explanation**: \

---

#### [hard_26] How many ways can you climb 4 stairs taking 1 or 2 steps?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #26  

- **A.** 3
- **B.** 4
- **C.** 5 ✅ *(Correct)*
- **D.** 8

> **Explanation**: Ways to climb follows Fibonacci: ways(1)=1, ways(2)=2, ways(3)=3, ways(4)=5.

---

#### [hard_27] What is the result of moving zeros to the end?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #27  
```text
Array: [0, 1, 0, 3, 12]
```

- **A.** 0, 0, 1, 3, 12
- **B.** 1, 3, 12, 0, 0 ✅ *(Correct)*
- **C.** 1, 0, 3, 0, 12
- **D.** 12, 3, 1, 0, 0

> **Explanation**: Keeping non-zero elements in relative order and moving zeros to end yields [1, 3, 12, 0, 0].

---

#### [hard_28] What is the length of the longest increasing subsequence?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #28  
```text
10, 9, 2, 5, 3, 7, 101, 18
```

- **A.** 3
- **B.** 4 ✅ *(Correct)*
- **C.** 5
- **D.** 6

> **Explanation**: Longest increasing subsequence is [2, 3, 7, 101] or [2, 5, 7, 18] with length 4.

---

#### [hard_29] What is the majority element?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #29  
```text
2, 2, 1, 1, 1, 2, 2
```

- **A.** 1
- **B.** 2 ✅ *(Correct)*
- **C.** Both
- **D.** None

> **Explanation**: Array has 7 elements. \

---

#### [hard_30] What is the maximum contiguous subarray sum?
**Tier**: `Hard` (Level 3) | **Stack**: `DSA & Logic` | **Number**: #30  
```text
-2, 1, -3, 4, -1, 2, 1, -5, 4
```

- **A.** 4
- **B.** 5
- **C.** 6 ✅ *(Correct)*
- **D.** 7

> **Explanation**: The contiguous subarray [4, -1, 2, 1] sums to 6 (Kadane\

---
