;;; navi2ch-jbbs-shitaraba.el --- View jbbs-shitaraba module for Navi2ch.

;; Copyright (C) 2002 by Navi2ch Project

;; Author:
;; Part5 $B%9%l$N(B 509 $B$NL>L5$7$5$s(B
;; <http://pc.2ch.net/test/read.cgi/unix/1013457056/509>

;; Keywords: 2ch, network

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; 

;;; Code:
(provide 'navi2ch-jbbs-shitaraba)

(require 'navi2ch-util)
(require 'navi2ch-multibbs)

(defvar navi2ch-js-func-alist
  '((bbs-p		. navi2ch-js-p)
    (subject-callback	. navi2ch-js-subject-callback)
    (article-update 	. navi2ch-js-article-update)
    (url-to-board   	. navi2ch-js-url-to-board)
    (url-to-article 	. navi2ch-js-url-to-article)
    (send-message   	. navi2ch-js-send-message)
    (send-success-p 	. navi2ch-js-send-message-success-p)
    (error-string   	. navi2ch-js-send-message-error-string)
    (article-to-url 	. navi2ch-js-article-to-url)))

(navi2ch-multibbs-regist 'jbbs-shitaraba navi2ch-js-func-alist)

;;-------------
	
(defun navi2ch-js-p (uri)
  "URI $B$,(BJBBS$B!w$7$?$i$P$J$i(B non-nil$B$rJV$9!#(B"
  (string-match "http://jbbs.shitaraba.com/" uri))

(defun navi2ch-js-subject-callback ()
  "subject.txt $B$r<hF@$9$k$H$-(B navi2ch-net-update-file
$B$G;H$o$l$k%3!<%k%P%C%/4X?t(B"
   (decode-coding-region (point-min) (point-max) 'euc-japan)
   (while (re-search-forward "\\([0-9]+\\.\\)cgi\\([^\n]+\n\\)" nil t)
     (replace-match "\\1dat\\2"))
   (encode-coding-region (point-min) (point-max) navi2ch-coding-system))

(defun navi2ch-js-article-update (board article)
  "BOARD ARTICLE$B$N5-;v$r99?7$9$k!#(B"
  (let ((file (navi2ch-article-get-file-name board article))
	(time (cdr (assq 'time article)))
	(url  (navi2ch-js-article-to-url board article))
	(func 'navi2ch-js-article-callback)
	ret)
    (setq ret (navi2ch-net-update-file url file time func))
    (list ret nil)))

(defun navi2ch-js-url-to-board (url)
  (let (uri id)
    (cond ((string-match
	    "\\(http://jbbs.shitaraba.com/[^/]+/\\([0-9]+\\)/\\)" url)
	   (setq uri (match-string 1 url)
		 id  (match-string 2 url)))
	  ((string-match
	    "\\(http://jbbs.shitaraba.com/[^/]+\\)/bbs/read\\.cgi.*BBS=\
\\([0-9]+\\)" url)
	   (setq uri (format "%s/%s/" (match-string 1 url) 
			     (match-string 2 url))
		 id  (match-string 2 url))))
    (if id (list (cons 'uri uri) (cons 'id id)))))

(defun navi2ch-js-url-to-article (url)
  (if (string-match
       "http://jbbs.shitaraba.com/[^/]+/bbs/read\\.cgi.*KEY=\\([0-9]+\\)" url)
      (list (cons 'artid (match-string 1 url)))))

(defun navi2ch-js-send-message 
  (from mail message subject bbs key time board article)
  (let ((url         (navi2ch-js-get-writecgi-url board))
	(referer     (navi2ch-board-get-uri board))
	(param-alist (list
		      (cons "submit" "$B=q$-9~$`(B")
		      (cons "NAME" (or from ""))
		      (cons "MAIL" (or mail ""))
		      (cons "MESSAGE" message)
		      (cons "BBS" bbs)
		      (cons "KEY" key)
		      (cons "TIME" time))))
    (navi2ch-net-send-request
     url "POST"
     (list (cons "Content-Type" "application/x-www-form-urlencoded")
	   (cons "Referer" referer))
     (let ((navi2ch-coding-system 'euc-japan))
       (navi2ch-net-get-param-string param-alist)))))

(defun navi2ch-js-send-message-success-p (proc)
  (string= "" (navi2ch-net-get-content proc)))

(defun navi2ch-js-send-message-error-string (proc)
  (decode-coding-string (navi2ch-net-get-content proc)
			'euc-japan))

(defun navi2ch-js-article-to-url
  (board article &optional start end nofirst)
  "BOARD, ARTICLE $B$+$i(B url $B$KJQ49!#(B
START, END, NOFIRST $B$OL5;k$9$k!#(B(jbbs.shitaraba$B$K$=$&$$$&5!G=$,L5$$(B)"
  (let ((uri   (cdr (assq 'uri board)))
	(artid (cdr (assq 'artid article))))
    (string-match "\\(.*\\)\\/\\([^/]*\\)\\/" uri)
    (format "%s/bbs/read.cgi?BBS=%s&KEY=%s"
	    (match-string 1 uri) (match-string 2 uri) artid)))

;;------------------

(defvar navi2ch-js-parse-regexp "\
<dt>\\([0-9]+\\) $BL>A0!'(B\\(<a href=\"mailto:\\([^\"]*\\)\">\\|<[^>]+>\\)\
<b> \\(.*\\) </b><[^>]+> $BEj9FF|!'(B \\(.*\\)<br><dd>\\(.*\\)<br><br>\n")
(defvar navi2ch-js-parse-subject-regexp "<title>\\([^\\n]*\\)</title>")

(defun navi2ch-js-parse-subject ()
  (re-search-forward navi2ch-js-parse-subject-regexp nil t)
  (match-string 1))

(defun navi2ch-js-parse ()
  (re-search-forward navi2ch-js-parse-regexp nil t))

(defun navi2ch-js-make-article (&optional subject)
  (let ((no (match-string 1))
	(mail (match-string 3))
	(name (match-string 4))
	(date (match-string 5))
	(contents (match-string 6)))
    (format "%s<>%s<>%s<>%s<>%s\n"
	    name (or mail "") date contents (or subject ""))))

(defun navi2ch-js-article-callback ()
  (let ((coding-system-for-read 'binary)
	(coding-system-for-write 'binary)
	(beg (point))
	subject)
    (decode-coding-region (point-min) (point-max) 'euc-japan)
    (setq subject (navi2ch-js-parse-subject))
    (while (navi2ch-js-parse)
      (insert (prog1 (navi2ch-js-make-article subject)
		(delete-region beg (point))))
      (setq subject nil)
      (setq beg (point)))
    (delete-region beg (point-max))
    (encode-coding-region (point-min) (point-max) navi2ch-coding-system)))

(defun navi2ch-js-get-writecgi-url (board)
  "write.cgi $B$N(B url $B$rJV$9(B"
  (let ((uri (navi2ch-board-get-uri board)))
    (string-match "\\(.+\\)/[^/]+/$" uri)
    (format "%s/bbs/write.cgi" (match-string 1 uri))))

;;; navi2ch-jbbs-shitaraba.el ends here