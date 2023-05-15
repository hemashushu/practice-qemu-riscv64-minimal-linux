/**
 * Copyright (c) 2023 Hemashushu <hippospark@gmail.com>, All rights reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include <stdio.h>

int main(void)
{
    printf("Hello, world!\n");
    printf("Press Ctrl+a, then press x to exit QEMU.\n");
    while (1)
    {
        int c = getchar();
        putchar(c);
    }
}
