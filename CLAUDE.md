# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This is a new, largely empty OpenSCAD project for designing Gridfinity-compatible parts (bins, baseplates, and accessories for the Gridfinity modular storage system). Currently the repository contains only an empty `gridfinity.scad` file, with no build tooling, tests, or documentation yet in place.

Since there is no established structure yet, use judgment when adding the first real code: OpenSCAD files are typically rendered/tested with the `openscad` CLI (e.g. `openscad -o out.stl gridfinity.scad` to render an STL, or `openscad gridfinity.scad` to open the GUI). Update this file with real commands and architecture notes once the project takes shape.
