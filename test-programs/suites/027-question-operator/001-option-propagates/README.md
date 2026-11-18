The ? operator on Option.  quarter() halves twice with ? and never
mentions the failure; show() proves both paths at run time -- 100 gives
25, and -4 gives the None that the FIRST ? handed back out of quarter
without the second one running.
