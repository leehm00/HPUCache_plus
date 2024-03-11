#!/bin/bash

grep -rn "$1" ./src/* | grep -v "Binary"
