FLAGS = -g -Wall -D_GNU_SOURCE

.PHONY: clean all

all: mult mult_trans

mult: mult.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

mult_trans: mult_trans.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

clean:
	rm -f *.o *.txt *~ mult mult_trans
