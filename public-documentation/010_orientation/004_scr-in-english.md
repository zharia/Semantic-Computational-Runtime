### What I’m building

Imagine that computers today are a bit like factories.

You give the factory a very detailed list of instructions:

> “Take this piece, move it there, calculate this number, store the result, then do the next thing.”

Computers are incredibly good at following those instructions, but there is a problem: **the computer doesn't really understand what the things mean.**

For example, it might know that something is a number, but it doesn't inherently know whether that number represents a temperature, a bank balance, the position of a car, or the weight of an object.

What I'm working on is called the **Semantic Computational Runtime**, or SCR.

The basic idea is to make a computer system that works at a higher level.

Instead of thinking primarily in terms of instructions, it thinks in terms of **things, their relationships, their state, and how those things can meaningfully change**.

---

### A simple example

Imagine a map of a city.

On the map there are:

* houses,
* roads,
* cars,
* people,
* shops,
* traffic lights.

And there are relationships between them:

> This car is on this road.
> This person is inside this building.
> This road connects these two places.

Now imagine something happens:

> “The traffic light changes from red to green.”

That isn't just a number changing from 0 to 1.

It has meaning.

It may cause:

> cars to start moving → traffic to change → other cars to slow down → people to reach different places.

SCR is designed to represent these things and their relationships directly.

So the computer can work with something closer to:

**“This thing changed because of this transformation, producing these possible consequences.”**

rather than immediately reducing everything to low-level computer instructions.

---

### Why is that useful?

Because the same idea can apply to many completely different things.

For example:

**A scientific simulation**

> The temperature of this region changes → which affects pressure → which affects air movement.

**An artificial intelligence system**

> The AI receives an observation → changes its internal state → makes a decision → performs an action.

**A financial system**

> Money moves from one account to another → balances change → another transaction becomes possible.

**A game or virtual world**

> A character moves → its position changes → it interacts with another object → the world changes.

These look like completely different computer programs today.

I'm exploring whether they can instead be described using the **same underlying computational principles**.

---

### The important part

I'm not trying to build another ordinary programming language.

I'm also not simply building another database, AI system, simulation program, or computer operating system.

I'm trying to build a **common foundation underneath those kinds of systems**.

The idea is roughly:

> **Describe what something means and how it can change, and then allow the computer to work out how to actually perform that computation.**

That means the same piece of meaningful computation could potentially be performed on different kinds of computers.

For example:

> “Perform this calculation.”

could potentially be carried out by a normal processor, a graphics processor, a specialised AI chip, or a large collection of computers.

The meaning stays the same; only the way it is physically carried out changes.

---

### Why is this difficult?

Computers have traditionally been built from the bottom upward.

First came the physical hardware.

Then machine instructions.

Then programming languages.

Then compilers and increasingly sophisticated software systems.

I'm approaching the problem from the other direction:

**What if we start with the meaning of the computation and work downward until we reach the hardware?**

That requires some fairly serious mathematics and computer science, because we need to make sure that changing the way something is represented doesn't accidentally change what it means.

That's why I'm currently spending a lot of time proving the foundations mathematically before trying to build the complete system.

---

### The unusual idea

One of the discoveries we've made while working on it is that a computation can naturally be thought of as a **relationship between an input and one or more possible consequences**.

For example:

> Starting state → transformation → resulting state

But sometimes there can be several possible results:

> Starting state → transformation → result A
> → result B
> → result C

That means computation can naturally form a kind of network or graph.

And once you have that, you can reason about things such as:

* what caused something to happen,
* what things can happen independently,
* what changes when something else changes,
* whether two different calculations mean the same thing,
* how a sequence of calculations fits together,
* and whether two different computer implementations produce the same meaningful result.

That is the part I'm particularly interested in.

---

### What could it become?

If the idea works, SCR could become a kind of **common foundation for advanced computer systems**.

It could potentially be used underneath things such as:

* artificial intelligence,
* scientific computing,
* simulations,
* robotics,
* digital versions of real-world systems,
* financial systems,
* games and virtual worlds,
* and large distributed computer systems.

It's a bit like trying to create a common language for **how computers represent and transform information with meaning**.

The important distinction is that I'm not claiming that it has already achieved all of that.

Right now, I'm building and testing the foundations to find out whether the idea really works.

If it does, the eventual goal is something quite ambitious:

> **A computer system where the fundamental unit of computation is not merely an instruction, but a meaningful transformation of structured information.**

In very simple terms:

**I'm trying to teach computers to work with the structure and meaning of information, rather than forcing everything to become low-level instructions before the computer can work with it.**
