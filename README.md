symbolic-math: a Lisp Symbolic Math Library
===========================================

Introduction
------------
This is a work-in-progress lisp library for symbolic math manipulation. The dialect used is Common Lisp. However, the code is mostly portable to other MacLisp variants like Emacs lisp. Just replace the call to defconstant with defconst.

Compiling & Loading
-------------------
To load this library, open a lisp interpreter and type `(load "symbolic.lisp")`

If you load this library often, you may choose to compile the library with `(compile-file "symbolic.lisp)` and load the following `.fas` or `.fasl`. Check your lisp implementation for more details.

Usage
-----
Symbolic evaluation of functions is supported by `simple-` functions.
Differentiation is supported by the `delta` function.

Supported Functions
-------------------
All elementary functions are currently implemented.