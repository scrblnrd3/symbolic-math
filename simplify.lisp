;;;; Functions for handling symbolic manipulation

(defconstant e (exp 1) "Euler's Number")  
(defconstant i #C(0 1) "Imaginary Number")
(defun ^ (a b) (expt a b))

(defvar *op* '((+ 1) (- 1) (* 1) (/ 1) (^ 1) (log 0)
	       (sin 0) (cos 0) (tan 0) (sinh 0) (cosh 0)
	       (tanh 0) (asin 0) (acos 0) (atan 0) (asinh 0)
	       (acosh 0) (atanh 0)))

(defun flatten (obj)
  (do* ((result (list obj))
        (node result))
       ((null node) (delete nil result))
    (cond ((consp (car node))
           (when (cdar node) (push (cdar node) (cdr node)))
           (setf (car node) (caar node)))
          (t (setf node (cdr node))))))

(defmacro simple-infix (a b operator &body clauses)
  `(cond ((and (numberp ,a) (numberp ,b))
	  (,operator ,a ,b))
	 ,@clauses
	 (t `(,a ,',operator ,b))))

(defmacro do-infix ((var1 var2) (var3 var4) &body body)
  `(dolist (,var1 '(0 2))
     (dolist (,var2 '(0 2))
       (let ((,var3 (- 2 ,var1)) (,var4 (- 2 ,var2)))
	 ,@body))))

(defmacro let-infix ((left right list) &body body)
  `(let ((,left (first ,list)) (,right (third ,list)))
     ,@body))

(defun greater-order (operator)
  (cond ((or (eql operator '+) (eql operator '-)) '*)
	((ot (eql operator '*) (eql operator '/)) '^)))

(defun like-order (operator)
  (cond ((or (eql operator '+) (eql operator '-)) '+)
	((or (eql operator '*) (eql operator '/)) '*)))

(defun lower-order (operator)
  (cond ((or (eql operator '*) (eql operator '/)) '+)
	((or (eql operator '^) '*))))

(defun exprp (object)
  (or (listp object) (symbolp object)))

(defun negative (object)
  (simple-* -1 object))

(defun plusify (list)
  (simple-+ (first list) (negative (third list))))

(defun operator-memberp (arg1 arg2 op1 op2)
  (and (listp arg1) (member op1 arg1)
       (listp arg2) (member op2 arg2)))

(defun combine-like (arg1 arg2 op)
  (let ((same-op (like-order op)))
    (do-infix (k j) (p q)
      (when (and (exprp (nth k arg1)) (exprp (nth j arg2)))
	(return-from combine-like
	  (simple same-op
		  (simple op (nth k arg1) (nth j arg2))
		  (simple op (nth p arg1) (nth q arg2))))))))

(defun combine-higher (arg1 arg2 op)
  (let ((big-op (greater-order op)))
    (do-infix (k j) (p q)
      (when (and (exprp (nth k arg1)) (exprp (nth j arg2)))
	(return-from combine-higher
	  (simple big-op (nth k arg1)
		  (simple op (nth p arg1) (nth q arg2))))))))

(defun combine-hybrid (arg1 arg2 op)
  (let ((big-op (greater-order op)))
    (do-infix (k j) (p q)
      (when (and (exprp (nth k arg1)) (exprp (nth j arg2)))
	(return-from combine-hybrid
	  (simple op (simple op arg1 (nth j arg2))
		  (nth q arg2)))))))

(defun combine-hybrid-atom (arg1 arg2 op)
  (let ((same-op (like-order op)))
    (do-infix (k j) (p q)
      (when (or (and (symbolp arg2) (exprp (nth k arg1)))
		(and (numberp arg2) (numberp (nth k arg1))))
	(return-from combine-hybrid-atom
	  (simple same-op (simple op (nth k arg1) arg2)
		  (nth p arg1)))))))

(defun identical (arg1 arg2)
  (or (equal arg1 arg2)
      (and (listp arg1) (listp arg2)
	   (not (set-difference (flatten arg1) (flatten arg2))))))

(defun simple-+ (a b)
  (simple-infix a b +
    ((equalp a 0) b) ((equalp b 0) a)
    ((identical a b) `(,2 * ,a))
    ((and (listp b) (eql (first b) '-))
     (simple-- a (second b)))
    ((operator-memberp a b '+ '+)
     (combine-like a b '+))
    ((operator-memberp a b '+ '-)
     (simple-+ a (plusify b)))
    ((operator-memberp a b '- '+)
     (simple-+ b a))			; Reverse order.
    ((operator-memberp a b '- '-)
     (simple-+ (plusify a) (plusify b))) ; Cheat.
    ((operator-memberp a b '* '*)
     (combine-higher a b '+))
    ((operator-memberp a b '* '+)
     (combine-hybrid a b '+))
    ((operator-memberp a b '+ '*)
     (simple-+ b a))			; Reverse order.
    ((operator-memberp a b '* '-)
     (simple-+ a (plusify b)))
    ((operator-memberp a b '- '*)
     (simple b a))
    ((and (listp a) (member '+ a) (atom b))
     (combine-hybrid-atom a b '+))
    ((and (listp b) (member '+ b) (atom a))
     (simple-+ b a))))			; Reverse order.

(defun simple-- (a b)
  (simple-infix a b -
    ((equalp a 0) (negative b)) ((equalp b 0) a)
    ((identical a b) 0)
    ((and (listp b) (eql (first b) '-))
     (simple-+ a (second b)))
    ((operator-memberp a b '+ '+)
     (combine-like a b '-))
    ((operator-memberp a b '+ '-)
     (simple-- a (plusify b)))
    ((operator-memberp a b '- '+)
     (negative (simple-- b a)))		; Reverse order.
    ((operator-memberp a b '- '-)
     (simple-- (plusify a) (plusify b))) ; Cheat.
    ((operator-memberp a b '* '*)
     (combine-higher a b '-))
    ((operator-memberp a b '* '+)
     (combine-hybrid a b '-))
    ((operator-memberp a b '+ '*)
     (negative (simple-- b a)))		; Reverse order.
    ((and (listp a) (member '- a) (atom b))
     (combine-hybrid-atom a b '-))
    ((and (listp b) (member '- b) (atom a))
     (negative (simple-- b a)))))

(defun simple-* (a b)
  (simple-infix a b *
    ((equalp a 0) 0) ((equalp b 0) 0) 
    ((equalp a 1) b) ((equalp b 1) a)
    ((identical a b) `(,a ^ ,2))
    ((and (listp b) (member '^ b) (member a b))
     (if (member-if #'numberp (member '^ b))
	 (simple-^ a (simple-+ (third b) 1))
	 (simple-^ a (simple-+ (first b) 1))))
    ((and (listp a) (member '^ a) (member b a))
     (if (member-if #'numberp (member '^ a))
	 (simple-^ b (simple-+ (third a) 1))
	 (simple-^ b (simple-+ (first a) 1))))))

(defun simple-/ (a b)
  (simple-infix a b /
    ((equalp a 0) 0) ((equalp b 0) `(,a / ,0))
    ((identical a b) 1)))

(defun simple-^ (a b)
  (simple-infix a b ^
    ((equalp a 0) 0) ((equalp b 0) 1)
    ((equalp a 1) 1) ((equalp b 1) a)))

(defun simple-prefix (operator a)
  (cond ((numberp a) (funcall operator a))
	(t `(,operator ,a))))

(defun simple-log (a)
  (cond ((or (eql a 'e) (equalp a e)) 1)
	(t `(log ,a))))
 
(defun simple (operator a &optional (b nil))
  (cond ((eql operator '+) (simple-+ a b))
	((eql operator '-) (simple-- a b))
	((eql operator '*) (simple-* a b))
	((eql operator '/) (simple-/ a b))
	((eql operator '^) (simple-^ a b))
	((eql operator 'log) (simple-log a))
	(t (simple-prefix operator a))))

(defun simplify (expr)
  (dolist (pair *op*)
    (when (atom expr) (return expr))
    (when (null (rest expr)) (return (simplify (first expr))))
    (when (eql (first expr) '-)
      (return (simple-* -1 (second expr))))
    (when (eql (first pair) (second expr))
      (return (simple (second expr) (simplify (first expr))
		      (simplify (third expr)))))
    (when (eql (first pair) (first expr))
      (return (simple (first expr) (simplify (second expr)))))))
