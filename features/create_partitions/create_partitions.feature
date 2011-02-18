# language: en
Feature: Create partitions
In order to have a disk image file with partitions
As a system administrator
I want to create partitions on an existing file as if it was a disk

Scenario: Create single primary partition
Given an empty file tmp/partition.img with size 1024 sectors
And the following partitions to create:
| kind     | start | end |
| primary  | 64    | 511 |
When I ask to create a fresh partition table
Then the list of partitions should be:
| kind     | start | end |
| primary  | 64    | 511 |

Scenario: Create two primary partitions
Given an empty file tmp/partition.img with size 1024 sectors
And the following partitions to create:
| kind     | start | end |
| primary  | 64    | 511 |
| primary  | 512   | 999 |
When I ask to create a fresh partition table
Then the list of partitions should be:
| kind     | start | end |
| primary  | 64    | 511 |
| primary  | 512   | 999 |

Scenario: Create single extended partition with one logical partition
Given an empty file tmp/partition.img with size 1024 sectors
And the following partitions to create:
| kind     | start | end |
| extended | 64    | 999 |
| logical  | 64    | 511 |
When I ask to create a fresh partition table
Then the list of partitions should be:
| kind     | start | end |
| extended | 64    | 999 |
| logical  | 64    | 511 |

Scenario: Create single extended partition with two logical partitions
Given an empty file tmp/partition.img with size 1024 sectors
And the following partitions to create:
| kind     | start | end |
| extended | 64    | 999 |
| logical  | 64    | 511 |
| logical  | 576   | 900 |
When I ask to create a fresh partition table
Then the list of partitions should be:
| kind     | start | end |
| extended | 64    | 999 |
| logical  | 64    | 511 |
| logical  | 576   | 900 |
