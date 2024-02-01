# ObjectGraphTools

Object Graph Tools

In PowerShell, Object Graphs are often used for applications along with modifying configurations resulted from e.g. [`Json`](https://www.json.org/json-en.html) or [DSC (Desired State Configuration)](https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-2.0). Yet, most existing object manipulation cmdlets (as [Sort-Object](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/sort-object) and [Compare-Object](https://learn.microsoft.com/nl-nl/powershell/module/microsoft.powershell.utility/sort-object)) are rather flat.\
This toolkit contains an [PowerShell object parser](./Docs/ObjectParser.md) and a set of Object Graph Cmdlets to deal with these complex recursive PowerShell objects.

**Quote [Wikipedia](https://en.wikipedia.org/)**

> In [computer science](https://en.wikipedia.org/wiki/Computer_science), in an [object-oriented program](https://en.wikipedia.org/wiki/Object-oriented_programming), groups of [objects](https://en.wikipedia.org/wiki/Object_(computer_science)) form a network through their relationships with each other, either through a direct [reference](https://en.wikipedia.org/wiki/Reference_(computer_science)) to another object or through a chain of intermediate references.
> These groups of objects are referred to as **object graphs**, after the mathematical objects called [graphs](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)) studied in [graph theory](https://en.wikipedia.org/wiki/Graph_theory).

## Tools

Currently the tool set includes:

* [`Get-Node`](./Docs/Get-Node.md)
* [`Get-ChildNode`](./Docs/Get-ChildNode.md)
* [`Compare-ObjectGraph`](./Docs/Compare-ObjectGraph.md)
* [`Merge-ObjectGraph`](./Docs/Merge-ObjectGraph.md)
* [`Sort-ObjectGraph`](./Docs/Sort-ObjectGraph.md)
* [`Copy-ObjectGraph`](./Docs/Copy-ObjectGraph.md)
* [`ConvertTo-Expression`](https://www.powershellgallery.com/packages/ConvertTo-Expression/) (under renovation, not yet included)

## Installation

```powershell
Install-Module -Name ObjectGraphTools
```
