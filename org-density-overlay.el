;;; org-density-overlay.el --- Overlay library -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://github.com/mtekman/org-density.el
;; Keywords: outlines
;; Package-Requires: ((emacs "26.1") (dash "2.17.0") (org "9.1.6"))
;; Version: 0.1

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; See org-density.el

;;; Code:
(defvar org-density-overlay--hashmap nil)

(defvar org-density-overlay--backupformat "%1$-5s--%3$d"
  "Fallback in case an invalid format is chosen by the user.")

(defcustom org-density-overlay-formats
  '((bardiffpercname . "%1$-5s |%3$-5d|%2$5.1f%%|%4$s")
    (bardiffperc . "%1$-5s |%3$-5d|%2$5.1f%%")
    (bardiffname . "%1$s%3$-5d|%4$s")
    (bardiff . "%1$s%3$d")
    (barname . "%1$-5s |%4$s")
    (bar . "%1$-5s")
    (percname . "%2$5.1f%%|%4$s")
    (perc . "%2$5.1f%%")
    (diffname . "%3$d|%4$s")
    (diff . "%3$d"))
  "Specify different formats to represent the density.
Some are given here as examples.  The first is the default used on startup.
The format takes 4 positional arguments:
 1. A string representing the percentage band as set in
    `org-density-percentlevels'.
 2. A float showing the current percentage
 3. An integer showing the number of lines/chars under the headline.
 4. A string with the name of headline."
  :type 'alist
  :group 'org-density)


(defcustom org-density-overlay-percentlevels
  '(((-9 .  1)  . ▏)
    (( 2 . 10)  . ▎)
    ((11 . 20)  . ▋)
    ((21 . 30)  . █)
    ((31 . 40)  . █▋)
    ((41 . 50)  . ██)
    ((51 . 60)  . ██▋)
    ((61 . 70)  . ███)
    ((71 . 80)  . ███▋)
    ((81 . 90)  . ████)
    ((91 . 110) . ████▋))
  "Set the percentage lower and upper bands and  the corresponding symbol."
  :type 'alist
  :group 'org-density)

(defun org-density-overlay--getformatline ()
  "Get format line, if custom, then use custom format string."
  (or (alist-get org-density-cycle--currentmode org-density-overlay-formats)
      (progn (message "using backup format.")
             org-density-overlay--backupformat)))


(defun org-density-overlay--gethashmap (&optional regenerate)
  "Retrieve or generate hashmap. If REGENERATE, then re-parse"
  (when regenerate
    (message "Regenerating")
    (org-density-parse--processvisible))
  org-density-overlay--hashmap)


(defun org-density-overlay--clear ()
  "Remove all overlays."
  (let ((ovs (overlays-in (point-min) (point-max))))
    (if (cl-loop for ov in ovs
                 thereis (overlay-get ov :org-density))
        (dolist (ov ovs)
          (when (overlay-get ov :org-density)
            (delete-overlay ov))))))


(defun org-density-overlay--setall (&optional regenerate)
  "Set the overlays from the hashtable. If regenerate is passed (as is the case) when called from org-cycle-hook, then regenerate the hash table."
  (org-density-overlay--clear)
  (let ((lineform (org-density-overlay--getformatline))
        (ntype (intern (format ":n%s" org-density-cycle--difftype)))
        (ptype (intern (format ":p%s" org-density-cycle--difftype))))
    (maphash
     (lambda (head info)
       (let ((bounds (plist-get info :bounds))
             (ndiffs (plist-get info ntype))
             (percer (plist-get info ptype))
             (leveln (car head))
             (header (cdr head)))
         ;; Have to choose either characters or lines at this
         ;; point to get the correct bar.
         (if percer
             (let ((oface (intern (format "org-level-%s" leveln)))
                   (ovner (make-overlay (car bounds) (cdr bounds)))
                   (barpc (cdr (--first (<= (caar it) (truncate percer)
                                            (cdar it))
                                        org-density-overlay-percentlevels))))
               (overlay-put ovner :org-density t)
               (overlay-put ovner 'face oface)
               (overlay-put ovner 'display
                            (format lineform barpc percer
                                    ndiffs header))))))
     (org-density-parse--gethashmap regenerate))))


(provide 'org-density-overlay)
;;; org-density-overlay.el ends here