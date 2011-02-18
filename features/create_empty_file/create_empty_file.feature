# language: en
Feature: Create Empty File
In order to have an empty file of some size for later use
As a system administrator
I want to create an empty file with exactly the right size

Scenario Outline: Create sparse empty file
Given that file <file> is removed if it existed
When I ask to create a file <file> with sparse disk usage and size <size>
Then the file should exist
And it should have size <size>
And it should have disk usage 1 block

Examples:
| file        | size |
| tmp/test123 | 1024 |
| tmp/test123 | 1 |
| tmp/test123 | 5 |
| tmp/test123 | 100000000 |
