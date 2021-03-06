
(require 'asdf)

(asdf:operate 'asdf:load-op 'kenzo)

(format t "~%Initializing Kenzo...")
(cat:cat-init)
(cat:kenzo-version)

(setf cat:*results-verbose* nil)

(format t "~%Creating simplicial set Moore(Z/2Z,3):")
(cat:def m23 (cat:moore 2 3))

(format t "~%~%Calculating the homology groups of dimensions 0 to 4:~%")
(cat:homology m23 0 5)

(format t "~%~%Creating the cartesian product Moore(Z/2Z,3)xMoore(Z/2Z,3):~%")
(cat:def m23xm23 (cat:crts-prdc m23 m23))

(let ((b (cat:basis m23xm23 6)))
  (format t "~%~%Basis in dimension 6:~%")
  (print b)
  (format t "~%~%Length: ~A~%" (length b)))

(format t "~%~%Creating the tensor product Moore(Z/2Z,3)#Moore(Z/2Z,3):~%")
(cat:def t2m23 (cat:tnsr-prdc m23 m23))

(format t "Basis in dimension 6: ~%")
(print (cat:basis t2m23 6))

(format t "~%~%Calculating the homology groups of dimensions 0 to 8:~%")
(cat:homology t2m23 0 8)

(format t "~%Creating the abelian simplicial group K(Z,1):")
(cat:def kz1 (cat:k-z 1))

(format t "~%~%Calculating coproduct:")
(print (cat:cprd kz1 4 '(2 3 4 5)))

(format t "~%~%Calculating product:")
(print (cat:aprd kz1 6 (cat:tnpr 2 '(1 2) 4 '(3 4 5 6))))

(format t "~%Creating the abelian simplicial group K(Z/2Z,2):")
(cat:def k-z2-2 (cat:k-z2 2))

(format t "~%~%Calculating the homology group of dimension 4:~%")
(cat:homology k-z2-2 4)

(format t "~%Creating sphere S^3:")
(cat:def s3 (cat:sphere 3))
(print s3)

(format t "~%Creating loop space Omega^2S^3:")
(cat:def o2s3 (cat:loop-space s3 2))

(format t "~%~%Calculating the homology groups of dimensions 4 to 6:~%")
(cat:homology o2s3 4 6)

(format t "~%Creating loop space Omega^1S^3:")
(cat:def os3 (cat:loop-space s3))

(format t "~%~%Creating the canonical generator of pi_2(Omega^1S^3):")
(cat:def L1 (cat:loop3 0 's3 1))

(cat:def null-simp (cat:absm 3 cat:+null-loop+))

(format t "~%~%Pasting a 3-simplex named D3 to Omega^1S^3:")
(cat:def dos3 (cat:disk-pasting os3 3 '<D3>
			       (list L1 null-simp L1 null-simp)))

(format t "~%~%Calculating the homology groups of dimensions 2 to 4:~%")
(cat:homology dos3 2 4)

(format t "~%~%Creating loop space of disk pasting space:")
(cat:def odos3 (cat:loop-space dos3))

(format t "~%~%Calculating the homology group of dimensions 5:~%")
(cat:homology odos3 5)

(format t "~%~%Is S^3 of type Kan? ~A~%" (typep s3 'cat:kan))

(format t "~%~%Is Omega^1S^3 a simplicial group? ~A~%"
	(typep os3 'cat:simplicial-group))

(format t "~%~%Is Omega^1S^3 an abelian simplicial group? ~A~%"
	(typep os3 'cat:simplicial-group))

(format t "~%~%Creating L2 = (S3)^2 in Omega^1S^3):")
(cat:def L2 (cat:loop3 0 's3 2))

(format t "~%~%Applying the product of the underlying algebra to L2#L2:")
(cat:def square (cat:aprd os3 4 (cat:tnpr 2 L2 2 L2)))

(format t "~%~%Select the generator part of the second element:")
(cat:def L4 (cat:gnrt (second (cat:cmbn-list square))))

(format t "~%~%Create the \"Kan hat\", the list of the faces 1, 2, 3, 4 of L4:")
(cat:def hat (mapcar #'(lambda (i) (cat:face os3 i 4 L4)) '(1 2 3 4)))

(format t "~%~%Try to find a filling of this \"Kan hat\":")
(cat:def kan-simplex (cat:kfll os3 0 4 hat))

(format t "~%~%Face two of the previous simplex is the same as face 2 of L4:")
(print (cat:face os3 2 4 kan-simplex))
(print (second hat))

(format t "~%~%Creating the classifying space of Omega^1S^3):")
(cat:def cls-os3 (cat:classifying-space os3))

(format t "~%~%Is it a simplicial group? ~A~%"
	(typep cls-os3 'cat:simplicial-group))

(format t "~%~%Verifying that its 4th homology is null:~%")
(cat:homology cls-os3 4)

(format t "~%~%Constructing the fundamental cohomology class of Moore(Z/2Z,3):")
(cat:def ch3 (cat:chml-clss m23 3))

(format t "~%~%Build a fibration over Moore(Z/Z2,3) associated w/ this class:")
(cat:def f3 (cat:z2-whitehead m23 ch3))

(format t "~%~%Build the fibration's total space:")
(cat:def x4 (cat:fibration-total f3))

(format t "~%~%The H_4 of this total space is the pi_4 of Moore(Z/2Z):~%")
(cat:homology x4 3 5)

(format t "~%~%We iterate the process to compute pi_5 of Moore(Z/2Z):~%")
(cat:def ch4 (cat:chml-clss x4 4))

(cat:def f4 (cat:z2-whitehead x4 ch4))

(cat:def x5 (cat:fibration-total f4))

(cat:homology x5 4 6)

(format t "~%~%Hence, pi_5(Moore(Z/2Z)) is Z/4Z. QED~%")

#+(or ccl ecl) (quit)
#+sbcl (sb-ext:exit)
