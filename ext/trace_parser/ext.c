#include <ruby.h>
#include <time.h>

#define DEBUG(msg) printf("%s,%d:%s\n",__FILE__,__LINE__,msg)
#define INSPECT(obj) RSTRING_PTR(rb_inspect(obj))
#define DEBUG_I(obj) DEBUG(INSPECT(obj))

static VALUE mTraceParser = Qnil;
static VALUE mTraceParserExt = Qnil;
static FILE* fp = NULL;
static clock_t tv = 0;

static ID sLine = 0;
static ID sCall = 0;
static ID sReturn = 0;
static ID sCCall = 0;
static ID sCReturn = 0;
static ID sMatcher = 0;

static long reg_match_pos(VALUE re, VALUE *strp, long pos);
static char* pcFilter = NULL;
static long lSzFilter = 0;

static VALUE rb_callback_function(int argc, VALUE *argv, VALUE self)
{
	if (!fp) return Qnil;
	if (argc != 6) return Qnil;

	if (pcFilter && strncmp(pcFilter, RSTRING_PTR(argv[1]), lSzFilter) == 0 ) return Qnil;

	double tv_diff = (double)(clock() - tv) / CLOCKS_PER_SEC;

	fprintf(fp, "%5.6f\t", tv_diff);
	fprintf(fp, "%s\t", RSTRING_PTR(argv[1]));  	// 1:[String]  file
	//fprintf(fp, "%d\t", SYM2ID(argv[1]));
	fprintf(fp, "%d\t", NUM2INT(argv[2]));		// 2:[Integer] line
							// 4:[Binding]
	fprintf(fp, "%s\t", INSPECT(argv[5]));		// 5:[Class]   classname
	fprintf(fp, "%s\t", INSPECT(argv[3]));		// 3:[Symbol]  id
	fprintf(fp, "%s\n", RSTRING_PTR(argv[0]));	// 0:[Symbol]  event

	return Qfalse;
}

static VALUE rb_enable(VALUE self, VALUE fd)
{
	if (!tv) {
		tv = clock();
	}

	if (!fp) {
		fp = fdopen(NUM2INT(fd), "a");
	}

	if (!pcFilter) {
		VALUE filter = rb_iv_get(mTraceParserExt, "filter");
		if (RTEST(filter)) {
			lSzFilter = RSTRING_LEN(filter);
			pcFilter = (char*)malloc(lSzFilter);

			strcpy(pcFilter, RSTRING_PTR(filter));
		}
	}

	return self;
}

static VALUE rb_disable(VALUE self)
{
	if (tv)
	{
		tv = 0;
	}

	if (fp)
	{
		fclose(fp);
		fp = NULL;
	}

	if (pcFilter)
	{
		free(pcFilter);
		pcFilter = NULL;
		lSzFilter = 0;
	}

	return self;
}

static VALUE rb_filter(VALUE self, VALUE filter)
{
	rb_iv_set(mTraceParserExt, "filter", filter);
	return filter;
}

void Init_ext()
{
	sLine   = rb_intern("line");
	sCall   = rb_intern("call");
	sReturn  = rb_intern("return");
	sCCall   = rb_intern("c-call");
	sCReturn = rb_intern("c-return");
	sMatcher = rb_intern("===");

	mTraceParser = rb_define_module("TraceParser");
	mTraceParserExt = rb_define_module_under(mTraceParser, "Ext");
	rb_define_singleton_method(mTraceParserExt, "filter=", rb_filter, 1);
	rb_define_singleton_method(mTraceParserExt, "enable", rb_enable, 1);
	rb_define_singleton_method(mTraceParserExt, "disable", rb_disable, 0);
	rb_define_singleton_method(mTraceParserExt, "callback_function", rb_callback_function, -1);

}
