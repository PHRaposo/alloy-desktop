(defpackage #:org.shirakumo.alloy.chroma.test
  (:use #:cl #:parachute)
  (:local-nicknames
   (#:chroma #:org.shirakumo.alloy.chroma)
   (#:colors #:org.shirakumo.alloy.chroma.colors))
  (:export #:chroma))

(in-package #:org.shirakumo.alloy.chroma.test)

(defun ~= (a b)
  (< (abs (- b a)) 0.0001))

(defun color~= (a b)
  (loop for channel in (chroma:channels a)
        always (~= (funcall channel a)
                   (funcall channel b))))

(define-test chroma)

(define-test type
  :parent chroma
  (finish (chroma:color 0 0 0))
  (finish (chroma:color 0 0 0 1))
  (finish (chroma:color 2 2 2 2))
  (of-type chroma:color (chroma:color 0 0 0))
  (is = 1.0 (chroma:r (chroma:color 1 2 3)))
  (is = 2.0 (chroma:g (chroma:color 1 2 3)))
  (is = 3.0 (chroma:b (chroma:color 1 2 3)))
  (is = 1.0 (chroma:a (chroma:color 1 2 3)))
  (is = 0.0 (chroma:a (chroma:color 0 0 0 0)))
  (is chroma:color= (chroma:color 1 0 0) colors:red)
  (is chroma:color= (chroma:color 0 1 0) colors:green)
  (isnt chroma:color= (chroma:color 0 0 0 0) (chroma:color 0 0 0 1))
  (is chroma:color-equal (chroma:color 0 0 0 0) (chroma:color 0 0 0 1))
  (let ((a 1))
    (true (chroma:color= (chroma:color 1 0 0) colors:red (chroma:color a 0 0)))
    (false (chroma:color= (chroma:color 0 0 0) colors:red (chroma:color a 0 0)))))

(define-test integer
  :parent chroma
  :depends-on (type)
  (is = #xFFFF (chroma:encode colors:red :channel-size 16 :channels '(r)))
  (is = #x0000 (chroma:encode colors:red :channel-size 16 :channels '(g)))
  (is = #x00FF (chroma:encode colors:red :channel-size 8  :channels '(g r)))
  (is chroma:color= colors:black (chroma:decode 0 :channel-size 8 :channels '(r g b)))
  (is chroma:color= colors:black (chroma:decode 0 :channel-size 8 :channels '(r)))
  (is chroma:color= colors:black (chroma:decode 0 :channel-size 8 :channels ()))
  (is chroma:color= colors:red (chroma:decode #xFF :channel-size 8 :channels '(r)))
  (is chroma:color= colors:red (chroma:decode #xFFFF :channel-size 16 :channels '(r)))
  (is chroma:color= colors:red (chroma:decode #xFF00 :channel-size 8 :channels '(r g))))

(define-test mapping
  :parent chroma
  :depends-on (type))

(defun round-trip (color type)
  (chroma:convert (chroma:convert color type) (type-of color)))

(define-test hsv
  :parent mapping
  (is = 0 (chroma:hue colors:red))
  (is = 120 (chroma:hue colors:green))
  (is = 240 (chroma:hue colors:blue))
  (is = 0 (chroma:hue colors:white))
  (is = 0 (chroma:hue colors:black))
  (is = 1 (chroma:saturation colors:red))
  (is = 0 (chroma:saturation colors:white))
  (is = 0 (chroma:saturation colors:black))
  (is = 0 (chroma:value colors:red))
  (is = 0 (chroma:value colors:white))
  (is = 0 (chroma:value colors:black))
  (is chroma:color= colors:red (round-trip colors:red 'chroma:hsv))
  (loop repeat 10
        for color = (chroma:rgb (random 1) (random 1) (random 1))
        do (is color~= color (round-trip color 'chroma:hsv))))

(define-test hsl
  :parent mapping
  (is = 0.5 (chroma:lightness colors:red))
  (is = 0.5 (chroma:lightness colors:green))
  (is = 1 (chroma:lightness colors:white))
  (is = 0 (chroma:lightness colors:black))
  (is chroma:color= colors:red (round-trip colors:red 'chroma:hsl))
  (loop repeat 10
        for color = (chroma:rgb (random 1) (random 1) (random 1))
        do (is color~= color (round-trip color 'chroma:hsl))))

(define-test hsi
  :parent mapping
  (is ~= 1/3 (chroma:intensity colors:red))
  (is ~= 1/3 (chroma:intensity colors:green))
  (is = 1 (chroma:intensity colors:white))
  (is = 0 (chroma:intensity colors:black))
  (is chroma:color= colors:red (round-trip colors:red 'chroma:hsi))
  (loop repeat 10
        for color = (chroma:rgb (random 1) (random 1) (random 1))
        do (is color~= color (round-trip color 'chroma:hsi))))
