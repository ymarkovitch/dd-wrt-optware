#!/bin/sh

rtrim_n(){
	awk '{printf("%s",$0);}'
}
