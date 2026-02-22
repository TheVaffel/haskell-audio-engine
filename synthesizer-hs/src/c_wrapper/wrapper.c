// wrapper.c

#include <stdlib.h>
#include <stdio.h>
#include "HsFFI.h"

void
init_hs (void)
{
  hs_init (NULL, NULL);
}

void
exit_hs (void)
{
  hs_exit ();
}
