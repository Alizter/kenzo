;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*

;;;  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS
;;;  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS
;;;  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS  SPECIAL-SMSTS

(IN-PACKAGE #:cat)

(PROVIDE "special-smsts")

;;; GMSM-FACES-INFO = (gmsm (simple-vector absm) . bndr)
;;;                         faces

(DEFUN FINITE-SS-PRE-TABLE (list)
  (declare (list list))
  (the list
       (let ((pre-rslt +empty-list+)
             (dmns-mark nil)
             (gmsm-mark nil))
         (declare (list pre-rslt dmns-mark gmsm-mark))
         (dolist (item list)
           (declare (type (or fixnum symbol list) item))
           (cond ((typep item 'fixnum)
                  (let ((found (assoc item pre-rslt)))
                    (declare (list found))
                    (setf dmns-mark
                          (or found
                              (car (push (list item) pre-rslt)))
                          gmsm-mark nil)))
                 ((symbolp item)
                  (when (assoc item (cdr dmns-mark))
                    (error "In BUILD-FINITE-SS, the symbol ~A is present two times."
                           item))
                  (setf gmsm-mark (car (push (list item) (cdr dmns-mark)))))
                 ((listp item)
                  (unless gmsm-mark
                    (error "In BUILD-FINITE-SS, the face list ~A~@
                              is not after a symbol." item))
                  (nconc gmsm-mark item)
                  (setf gmsm-mark nil))
                 (t
                  (error "In BUILD-FINITE-SS, the argument ~A does not make sense." item))))
         (do ((mark1 pre-rslt (cdr mark1)))
             ((endp mark1))
           (declare (list mark1))
           (do ((mark2 (rest mark1) (cdr mark2)))
               ((endp mark2))
             (declare (list mark2))
             (let ((inter (intersection (cdar mark1) (cdar mark2)
                                        :key #'first)))
               (declare (list inter))
               (when inter
                 (error "In BUILD-FINITE-SS, the symbol ~A is present two times."
                        (caar inter))))))
         pre-rslt)))


(DEFUN FINITE-SS-PRE-TABLE-TABLE (pre-table)
  (declare (list pre-table))
  (let* ((maxdim (1+ (apply #'max (mapcar #'first pre-table))))
         (table (make-array maxdim :initial-element +empty-list+)))
    (declare
     (fixnum maxdim)
     (simple-vector table))
    (dolist (item pre-table)
      (declare (list item))
      (setf (svref table (first item))
            (sort (rest item) #'string< :key #'first)))
    table))


(DEFUN FINITE-SS-FIND-GMSM (table gmsm dmns &optional (max-dmns (1+ dmns)))
  (declare
   (type gmsm gmsm)
   (fixnum dmns max-dmns))
  (do ((dmns dmns (1+ dmns)))
      ((>= dmns max-dmns) nil)
    (declare (fixnum dmns))
    (let ((found (find gmsm (svref table dmns) :test #'eq :key #'car)))
      (declare (type (or cons null) found))
      (when found
        (return-from finite-ss-find-gmsm dmns)))))


(DEFUN FINITE-SS-FINISH-TABLE (table bspn)
  (declare (simple-vector table))
  (dotimes (dmns (length table))
    (declare (fixnum dmns))
    (finite-ss-finish-line table dmns bspn))
  table)


(DEFUN FINITE-SS-FINISH-LINE (table dmns bspn)
  (declare
   (simple-vector table)
   (fixnum dmns))
  (setf (svref table dmns)
        (mapcar
         #'(lambda (entry)
             (finite-ss-finish-entry table entry dmns bspn))
         (svref table dmns))))


(DEFUN FINITE-SS-FINISH-ENTRY (table entry dmns bspn)
  (declare
   (simple-vector table)
   (list entry)
   (fixnum dmns)
   (symbol bspn))
  (let ((simplex (first entry))
        (faces (rest entry)))
    (declare
     (symbol simplex)
     (list faces))
    (when (zerop dmns)
      (return-from finite-ss-finish-entry
        (make-gmsm-faces-info
         :gmsm simplex :faces +s-empty-vector+
         :bndr +zero-negative-cmbn+)))
    (setf faces (nconc faces (make-list (1+ (- dmns (length faces)))
                                        :initial-element bspn)))
    (let ((rslt (make-gmsm-faces-info :gmsm simplex)))
      (declare (cons rslt))
      (flet ((process-face (face)
               (declare (type (or symbol list) face))
               (when (symbolp face)
                 (setf face (list face)))
               (let* ((gmsm2 (car (last face)))
                      (dgop-ext (nbutlast face))
                      (dmns2 (finite-ss-find-gmsm table gmsm2 0 dmns)))
                 (declare
                  (symbol gmsm2)
                  (list dgop-ext)
                  (type (or fixnum null) dmns2))
                 (unless dmns2
                   (error "In BUILD-FINITE-SS, the face ~A is absent." gmsm2))
                 (when (zerop (length dgop-ext))
                   (setf dgop-ext (nreverse (<a-b< dmns2 (1- dmns)))))
                 (unless (= (+ (length dgop-ext) dmns2 1) dmns)
                   (error "In BUILD-FINITE-SS, the face ~A has a wrong dimension."
                          (append dgop-ext (list gmsm2))))
                 (absm (dgop-ext-int dgop-ext) gmsm2))))
        (setf (info-faces rslt)
              (map 'simple-vector #'process-face faces))
        (setf (info-bndr rslt)
              (apply #'nterm-add #'s-cmpr (1- dmns)
                     (do ((rslt +empty-list+)
                          (faces (info-faces rslt))
                          (indx dmns (1- indx)))
                         ((minusp indx) rslt)
                       (declare
                        (list rslt)
                        (simple-vector faces)
                        (fixnum indx))
                       (let ((face (svref faces indx)))
                         (declare (type absm face))
                         (unless (degenerate-p face)
                           (push (term (-1-expt-n indx) (gmsm face))
                                 rslt))))))
        rslt))))


(DEFUN FINITE-SS-TABLE (list)
  (declare (list list))
  (setf list (cons 0 list))
  (let* ((bspn (second list))
         (pre-table (finite-ss-pre-table list))
         (table (finite-ss-pre-table-table pre-table)))
    (declare
     (symbol bspn)
     (list pre-table)
     (simple-vector table))
    ;; (vector (vector gmsm-faces-info))
    (finite-ss-finish-table table bspn)))


(DEFUN FINITE-SS-BASIS (table)
  (declare (simple-vector table))
  (flet ((rslt (dmns)
           (declare (fixnum dmns))
           (the list
                (if (< -1 dmns (length table))
                    (mapcar #'car (svref table dmns))
                    +empty-list+))))
    #'rslt))


(DEFUN FINITE-SS-FACE (ind-smst table)
  (declare
   (symbol ind-smst)
   (simple-vector table))
  (flet ((rslt (indx dmns gmsm)
           (declare
            (fixnum indx dmns)
            (symbol gmsm))
           (let ((found (find gmsm (svref table dmns) :key #'car)))
             (unless found
               (error "In the finite simplicial set ~A,~@
                         the simplex ~A is absent in dimension ~D."
                      (eval ind-smst) gmsm dmns))
             (svref (info-faces found) indx))))
    #'rslt))


(DEFUN FINITE-SS-INTR-BNDR (ind-smst table)
  (declare
   (symbol ind-smst)
   (simple-vector table))
  (flet ((rslt (dmns gmsm)
           (declare
            (fixnum dmns)
            (symbol gmsm))
           (let ((found (find gmsm (svref table dmns) :key #'car)))
             (unless found
               (error "In the finite simplicial set ~A,~@
                         the simplex ~A is absent in dimension ~D." (eval ind-smst) gmsm dmns))
             (info-bndr found))))
    #'rslt))


(DEFUN BUILD-FINITE-SS (list)
  (declare (list list))
  (let ((bspn (first list))
        (table (finite-ss-table list))
        (ind-smst (gensym)))
    (declare
     (symbol bspn ind-smst)
     (simple-vector table))
    ;;  (vector (vector gmsm-faces-info))
    (let ((rslt (build-smst
                 :cmpr #'s-cmpr
                 :basis (finite-ss-basis table)
                 :bspn bspn
                 :face (finite-ss-face ind-smst table)
                 :intr-bndr (finite-ss-intr-bndr ind-smst table)
                 :bndr-strt :gnrt
                 :orgn `(build-finite-ss ,list))))
      (setf (symbol-value ind-smst) rslt)
      (inspect rslt)
      (unless (check-smst rslt 0 (length table))
        (pop *smst-list*)
        (pop *chcm-list*)
        (pop *mrph-list*)
        (return-from build-finite-ss nil))
      rslt)))


(DEFUN SPHERE-CMPR (gmsm1 gmsm2)
  (declare (ignore gmsm1 gmsm2))
  (the cmpr :equal))


(DEFUN SPHERE-BASIS (dmns)
  (declare (fixnum dmns))
  (let ((fund-gmsm (intern (format nil "S~D" dmns))))
    (declare (symbol fund-gmsm))
    (flet ((rslt (dmns2)
             (declare (fixnum dmns2))
             (cond ((zerop dmns2)
                    (list '*))
                   ((= dmns2 dmns)
                    (list fund-gmsm))
                   (t
                    +empty-list+))))
      (the basis #'rslt))))


(DEFUN SPHERE-FACE (dmns)
  (declare (fixnum dmns))
  (let ((face (absm (mask (1- dmns)) '*)))
    (declare (type absm face))
    (flet ((rslt (indx dmns2 gmsm)
             (declare (ignore indx dmns2 gmsm))
             (the absm face)))
      #'rslt)))


(DEFUN SPHERE (dmns)
  (declare (fixnum dmns))
  (unless (plusp dmns)
    (error "In SPHERE, the dimension ~D should be positive." dmns))
  (unless (< dmns +maximal-dimension+)
    (error "In SPHERE, the dimension ~D should be < ~D."
           dmns +maximal-dimension+))
  (the simplicial-set
       (let ((rslt (build-smst
                    :cmpr #'sphere-cmpr
                    :basis (sphere-basis dmns)
                    :bspn '*
                    :face (sphere-face dmns)
                    :intr-bndr #'zero-intr-dffr
                    :bndr-strt :cmbn
                    :orgn `(sphere ,dmns))))
         (declare (type simplicial-set rslt))
         (setf (slot-value (bndr rslt) 'orgn)
               `(zero-mrph ,rslt ,rslt -1))
         rslt)))


(DEFUN SPHERE-WEDGE-BASIS (dmns-list)
  (declare (list dmns-list))
  (flet ((rslt (dmns)
           (declare (fixnum dmns))
           (when (zerop dmns)
             (return-from rslt '(*)))
           (do ((i (count dmns dmns-list) (1- i))
                (basis +empty-list+
                       (cons (intern (format nil "S~D-~D" dmns i))
                             basis)))
               ((zerop i) basis)
             (declare
              (fixnum i)
              (list basis)))))
    (the basis #'rslt)))


(DEFUN SPHERE-WEDGE-FACE (indx dmns gmsm)
  (declare
   (ignore indx gmsm)
   (fixnum dmns))
  (the absm
       (absm (mask (1- dmns)) '*)))

(DEFUN SPHERE-WEDGE (&rest dmns-list)
  (declare (list dmns-list))
  (the simplicial-set
       (let ((rslt (build-smst
                    :cmpr #'s-cmpr
                    :basis (sphere-wedge-basis dmns-list)
                    :face #'sphere-wedge-face
                    :intr-bndr #'zero-intr-dffr
                    :bndr-strt :cmbn
                    :orgn `(sphere-wedge ,@dmns-list))))
         (declare (type simplicial-set rslt))
         (setf (slot-value (bndr rslt) 'orgn)
               `(zero-mrph ,rslt ,rslt -1))
         rslt)))


(DEFUN MOORE-CMPR (gmsm1 gmsm2)
  (declare (ignore gmsm1 gmsm2))
  (the cmpr :equal))


(DEFUN MOORE-BASIS (dmns)
  (declare (fixnum dmns))
  (let ((lgmsm1 (list (intern (format nil "M~D" dmns))))
        (lgmsm2 (list (intern (format nil "N~D" (1+ dmns))))))
    (declare (list lgmsm1 lgmsm2))
    (flet ((rslt (dmns2)
             (declare (fixnum dmns2))
             (cond ((zerop dmns2) '(*))
                   ((= dmns dmns2) lgmsm1)
                   ((= (1+ dmns) dmns2) lgmsm2)
                   (t +empty-list+))))
      (the basis #'rslt))))


(DEFUN MOORE-FACE (pii dmns)
  (declare (fixnum pii dmns))
  (let ((face (absm 0 (intern (format nil "M~D" dmns))))
        (bspn1 (absm (mask (1- dmns)) '*))
        (bspn2 (absm (mask dmns) '*))
        (2pii (ash pii 1)))
    (declare
     (type absm face)
     (type absm bspn1 bspn2)
     (fixnum 2pii))
    (flet ((rslt (indx dmns2 gmsm)
             (declare
              (fixnum indx dmns2)
              (ignore gmsm))
             (the absm
                  (if (= dmns dmns2)
                      bspn1
                      (if (oddp indx)
                          bspn2
                          (if (< indx 2pii)
                              face
                              bspn2))))))
      (the face #'rslt))))


(DEFUN MOORE-INTR-BNDR (pii dmns)
  (declare (fixnum pii dmns))
  (let ((1+dmns (1+ dmns))
        (gmsm1 (intern (format nil "M~D" dmns))))
    (declare
     (fixnum 1+dmns)
     (type symbol gmsm1))
    (flet ((rslt (cmbn)
             (declare
              (type cmbn cmbn))
             (with-cmbn (degr list) cmbn
                        (unless list
                          (return-from rslt (zero-cmbn (1- (cmbn-degr cmbn)))))
                        (if (= degr 1+dmns)
                            (term-cmbn dmns (* (cffc (first list)) pii) gmsm1)
                            (zero-cmbn (1- (cmbn-degr cmbn)))))))
      (the intr-mrph #'rslt))))


(DEFUN MOORE (pii dmns)
  (declare (fixnum pii dmns))
  (the simplicial-set
       (build-smst
        :cmpr #'moore-cmpr
        :basis (moore-basis dmns)
        :face (moore-face pii dmns)
        :intr-bndr (moore-intr-bndr pii dmns)
        :bndr-strt :cmbn
        :orgn `(moore ,pii ,dmns))))


(DEFUN R-PROJ-SPACE-CMPR (gmsm1 gmsm2)
  (declare (ignore gmsm1 gmsm2))
  (the cmpr :equal))


(DEFUN R-PROJ-SPACE-BASIS (k l)
  (declare (fixnum k) (type (or (eql :infinity) fixnum) l))
  (the basis
       (progn
         (when (eq l :infinity)
           (setf l most-positive-fixnum))
         (flet
             ((rslt (dmns)
                (declare (fixnum dmns))
                (the list
                     (if (or (minusp dmns)
                             (< 0 dmns k)
                             (>= dmns l))
                         +empty-list+
                         (list dmns)))))
           (the basis #'rslt)))))


(DEFUN R-PROJ-SPACE-FACE (k)
  (declare (fixnum k))
  (flet ((rslt (indx dmns gmsm)
           (declare
            (fixnum indx dmns)
            (ignore gmsm))
           (if (<= dmns k)
               (absm (mask (1- dmns)) 0)
               (if (or (zerop indx)
                       (= indx dmns))
                   (absm 0 (1- dmns))
                   (if (= dmns (1+ k))
                       (absm (mask (1- dmns)) 0)
                       (absm (2-exp (1- indx)) (- dmns 2)))))))
    (the face #'rslt)))


(DEFUN R-PROJ-SPACE-INTR-BNDR (k)
  (declare (fixnum k))
  (flet ((rslt (cmbn)
           (declare (type cmbn cmbn))
           (with-cmbn (degr list) cmbn
                      (unless list
                        (return-from rslt (zero-cmbn (1- degr))))
                      (if (<= degr k)
                          (zero-cmbn (1- degr))
                          (if (evenp degr)
                              (make-cmbn
                               :degr (1- degr)
                               :list (list (term (* 2 (-cffc list)) (1- degr))))
                              (zero-cmbn (1- degr)))))))
    (the intr-mrph #'rslt)))

(DEFUN R-PROJ-SPACE (&optional (l :infinity) (k 1))
  (declare (fixnum k) (type (or fixnum (eql :infinity))))
  (assert
   (and (typep k 'fixnum)
        (plusp k)
        (or (eq l :infinity)
            (and (typep l 'fixnum)
                 (<= k l)))))
  (the simplicial-set
       (build-smst
        :cmpr #'R-proj-space-cmpr
        :basis (R-proj-space-basis k l)
        :bspn 0
        :face (R-proj-space-face k)
        :intr-bndr (R-proj-space-intr-bndr k)
        :bndr-strt :cmbn
        :orgn `(R-proj-space ,k ,l))))


;;; Constructing a small simplicial subset
;;; from a combination of simplices.

(DEFUN CMBN-GMSMS (cmbn)
  (declare (type cmbn cmbn))
  (the list
       ;; Returns a list made of:
       ;;   the degree of the combination;
       ;;   the list of simplex generators of the combinations.
       (cons (cmbn-degr cmbn) (mapcar #'cdr (cmbn-list cmbn)))))


(DEFUN GMSMS-SUBSMST (smst gmsms
                      &aux
                        (dmns (typecase gmsms
                                (cmbn (cmbn-degr gmsms))
                                (otherwise (first gmsms))))
                        (cmpr= #'(lambda (gmsm1 gmsm2)
                                   (declare (type gmsm gmsm1 gmsm2))
                                   (the boolean
                                        (eq (cmpr smst gmsm1 gmsm2) :equal)))))
  (declare
   (type simplicial-set smst)
   (type (or cmbn list) gmsms)
   (fixnum dmns)
   (type (function (gmsm gmsm) boolean) cmpr=))
  (when (typep gmsms 'cmbn)
    (setf gmsms (cmbn-gmsms gmsms)))
  (the (values simplicial-set morphism)
       (let ((prslt (make-array (1+ dmns) :initial-element +empty-list+)))
         (declare (type simple-vector prslt))
         (setf (svref prslt dmns) (rest gmsms))
         (do ((d dmns (1- d)))
             ((zerop d))
           (declare (fixnum d))
           (dolist (gmsm (svref prslt d))
             (declare (type gmsm gmsm))
             (dotimes (iface (1+ d))
               (declare (fixnum iface))
               (with-absm (dgop gmsm) (face smst iface d gmsm)
                          (declare (fixnum dgop) (type gmsm gmsm))
                          (pushnew gmsm (svref prslt (- d 1 (logcount dgop)))
                                   :test cmpr=)))))
         (let ((rslt-basis #'(lambda (k)
                               (declare (fixnum dmns))
                               (the list
                                    (if (<= 0 k dmns)
                                        (aref prslt k)
                                        +empty-list+)))))
           (declare (type (function (fixnum) list) rslt-basis))
           (let ((subsmst (build-smst
                           :cmpr (cmpr smst)
                           :basis rslt-basis
                           :bspn (let ((bspn (bspn smst)))
                                   (declare (type gmsm bspn))
                                   (pushnew bspn (svref prslt 0) :test cmpr=)
                                   bspn)
                           :face (face smst)
                           :orgn `(gmsms-subsmst ,gmsms))))
             (declare (type simplicial-set subsmst))
             (values subsmst
                     (build-mrph :sorc subsmst
                                 :trgt smst
                                 :degr 0
                                 :intr #'(lambda (cmbn)
                                           (declare (type cmbn cmbn))
                                           (the cmbn cmbn))
                                 :strt :cmbn
                                 :orgn `(gmsms-subsmst-incl ,gmsms))))))))

(defun absm-ext-int (vlist)
  (do ((dgop nil)
       (gmsm (list (first vlist)))
       (mark (rest vlist) (cdr mark))
       (idgop 0 (1+ idgop)))
      ((endp mark) (absm (dgop-ext-int dgop)
                         (dgop-ext-int gmsm)))
    (if (= (first gmsm) (car mark))
        (push idgop dgop)
        (push (car mark) gmsm))))


(defun absm-int-ext (absm)
  (with-absm
      (dgop gmsm) absm
      (do ((dgop (nreverse (dgop-int-ext dgop)))
           (gmsm (rest (dlop-int-ext gmsm)))
           (i 0 (1+ i))
           (rslt (list (first (dlop-int-ext gmsm)))))
          ((and (endp dgop) (endp gmsm)) (nreverse rslt))
        (if dgop
            (if (= i (car dgop))
                (progn
                  (pop dgop)
                  (push (first rslt) rslt))
                (push (pop gmsm) rslt))
            (return (nreconc rslt gmsm))))))


(defun vertex-i (absm i)
  (with-absm
      (dgop gmsm) absm
      (let ((dgop (nreverse (dgop-int-ext dgop)))
            (gmsm (dlop-int-ext gmsm)))
        (do ((dgop-mark dgop)
             (gmsm-mark gmsm)
             (ii 0 (1+ ii)))
            ((= i ii) (car gmsm-mark))
          (if (and dgop-mark
                   (= ii (car dgop-mark)))
              (pop dgop-mark)
              (pop gmsm-mark))))))
