
{$define TORO_VERSION := 1 }
{$define TORO_RELEASE := 1 }
{$define TORO_PATCH := 3 }

{$define TORO_MSG :=
printk('/nkernel version ... /V%d.%d.%d /nby Matias Vara\n',[TORO_VERSION,TORO_RELEASE,TORO_PATCH],[]);
printk('/ncompilador/n ... Freepascal /V%d.%d.%d\n',[FPC_VERSION,FPC_RELEASE,FPC_PATCH],[]);
printk('\n',[],[]);
}
