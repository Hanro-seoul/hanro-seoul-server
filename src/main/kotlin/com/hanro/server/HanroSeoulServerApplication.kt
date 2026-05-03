package com.hanro.server

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class HanroSeoulServerApplication

fun main(args: Array<String>) {
    runApplication<HanroSeoulServerApplication>(*args)
}
