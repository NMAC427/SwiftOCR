# swift-auto-diagram
A Ruby script that scans all swift code from the specified folders and files and automatically generates an entity diagram (similar to a class diagram) which can be viewed in a browser.

# Usage:
In terminal run:
```ruby
$ ruby generateEntityDiagram.rb
```
If you don't specify any command line arguments then the script will search for all swift files in the script's main directory.
You can specify any number of command line arguments which should be existing directory or file paths. The directories will be searched in depth for swift files recursively.

# Tutorial:
https://martinmitrevski.com/2016/10/12/swift-class-diagrams-and-more/

# Notice:
The state of the project is still in a beta version which means it still may not run or may be not accurate for all projects.
We hope to see more contributors help make this a wonderful developer tool even better.

# Initial contributors:
Jovan Jovanovski & Zdravko Nikolovski
