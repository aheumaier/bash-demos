---
documentclass: scrartcl
papersize: a4
linkcolor: blue
classoption:
  - oneside
header-includes:
  - \usepackage[english]{babel}
  - \usepackage[T1]{fontenc}
  - \usepackage{booktabs}
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhf{}
  - \rhead{Introduction}
  - \lhead{Scripting with Bash}
  - \cfoot{Andreas Heumaier <andreas.heumaier@microsoft>}
---
>This is a multi part series capturing learnings that came out of a longer CI-centered Tier-1 cloud infrastructure project where BASH Scripts where the glue of ~~all~~ *most* of the things. There are no fundamentals or starters - [there are better ones than this](https://tldp.org/LDP/abs/html/). The intended adience is the intermediuate software enginheer advancing from simple scripting to programmming BASH.



# Writing clean shell scripts
Since Bash has several [known weaknesses](https://mywiki.wooledge.org/BashWeaknesses) I don't enjoy writing such code that much. It's often used when all you want is automate a mundane task. *"I'll just copy/paste the commands I usually run, add a few IFs and FORs and that will be enough"*.  Well, that's how many shell scripts come to existence I guess, but nonetheless writing such scripts is not as easy as it sounds, and there are many pitfalls to avoid. 

The shell is a paradox. It is mysterious in its complexity and marvelous in its simplicity. You can learn the bare basics with just of couple hours of tinkering, but becoming a shell master takes years of consistent use, and even then it feels like you learn something new every day. On one hand, it has an ugly syntax, and trying to work with strings and arrays is beyond frustrating. On the other hand, there’s nothing quite like the zen achieved when you stitch together a half dozen shell commands to extract and format your data of interest, creating a pipeline that outperforms any Python or C++ code you could ever write.

Whatever your feelings about the shell in general, or about (the most popular shell) Bash in particular, you cannot deny that it is a rustic language with very poor debugging facilities that makes it very easy to shoot yourself in the foot. If you can avoid writing code in Bash, you should. In fact, as some say, if you can avoid writing code at all, you should. But if you’re a modern engineer then chances are that sooner or later the shell will be the best tool for a particular job. What do you do then?

Over the last few months I’ve really tried to look for ways to improve my shell code. .

[Here are some of the learnings I’ve found](best-practices.md).

So the next time you absolutely, positively have to write some shell code, consider referring to these resources to improve the experience!
