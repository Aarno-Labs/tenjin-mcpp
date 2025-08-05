#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mcpp_bin="$dir/../src/mcpp"

input=""
output="/dev/stdout"
args=()

# System includes from clang
clang_sys_includes=($(clang -E -x c - -v < /dev/null 2>&1 |
  awk '/#include <...> search starts here:/ {flag=1; next}
       /End of search list./ {flag=0}
       flag { print "-I" $1 }'))

# Handle arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -D|-U|-I|-include|-iquote|-isystem)
      [[ $# -gt 1 ]] && args+=("$1$2") && shift
      ;;
    -D*|-U*|-I*|-include*|-iquote*|-isystem*)
      args+=("$1")
      ;;
    -MD|-MF|-MT|-MP|-MQ)
      shift ;; # skip next token
    -o)
      output="$2"; shift ;;
    -o*)
      output="${1:2}" ;;
    -*)
      ;; # skip unknown flags
    *)
      [[ -z "$input" && -f "$1" ]] && input="$1"
      ;;
  esac
  shift
done

[[ -z "$input" ]] && {
  echo "mcpp_preprocess.sh: ERROR: No input file provided." >&2
  exit 1
}

[[ "$output" == *.o ]] && output="${output%.o}.i"

# Filter and extract only useful Clang macros
function gen_defines() {
  clang -dM -E -x c - < /dev/null |
  awk '
    /^#define/ {
      name = $2
      # Exclude known noisy or compiler-internal macros
      if (name ~ /^__/ &&
          name !~ /^__GNUC/ &&
          name !~ /^__clang/ &&
          name !~ /^__x86_64__/ &&
          name !~ /^__i386__/ &&
          name !~ /^__aarch64__/ &&
          name !~ /^__arm__/ &&
          name !~ /^__unix__/ &&
          name !~ /^__STDC/ &&
          name !~ /^__VERSION__/ &&
          name !~ /^__builtin_/ &&
          name !~ /^__GCC_HAVE_/ &&
          name !~ /^__DBL_/ &&
          name !~ /^__FLT_/ &&
          name !~ /^__LDBL_/ &&
          name !~ /^__SCHAR_/ &&
          name !~ /^__SHRT_/ &&
          name !~ /^__INT_/ &&
          name !~ /^__LONG_/ &&
          name !~ /^__SIZEOF_/ &&
          name !~ /^__SIZE_TYPE__/ &&
          name !~ /^__CHAR_/ &&
          name !~ /^__PTRDIFF_/ &&
          name !~ /^__UINT_/ &&
          name !~ /^__WCHAR_/ &&
          name !~ /^__WINT_/ &&
          name !~ /^__SIG_ATOMIC_/ &&
          name !~ /^__INTMAX_/ &&
          name !~ /^__UINTMAX_/ &&
          name !~ /^__INTPTR_/ &&
          name !~ /^__UINTPTR_/ &&
          name !~ /^__OBJC_/ &&
          name !~ /^__USER_LABEL_PREFIX__/ &&
          name !~ /^__REGISTER_PREFIX__/ &&
          name !~ /^__GXX/ &&
          name !~ /^__CLANG/ &&
          name !~ /^__llvm__/ &&
          name !~ /^__SANITIZE/ &&
          name !~ /^__OPTIMIZE__/ &&
          name !~ /^__NO_INLINE__/ &&
          name !~ /^__FAST_MATH__/ &&
          name !~ /^__PIC__/ &&
          name !~ /^__pie__/ &&
          name !~ /^__attribute__/ &&
          name !~ /^__declspec__/ &&
          name !~ /^__extension__/ &&
          name !~ /^__has_/)
        next

      $1 = ""; $2 = ""
      val = substr($0, 2)
      gsub(/^ +| +$/, "", val)
      printf("-D%s=%s\n", name, val)
    }'
}

mapfile -t extra_macros < <(gen_defines)

# Append fallback feature macros required by headers
extra_macros+=(
  "-D__has_include_next(x)=0"
  "-D__has_feature(x)=0"
  "-D__building_module(x)=0"
  "-D__has_extension(x)=0"
  "-D__has_cpp_attribute(x)=0"
)

clang_version=$(
  clang -dM -E -x c /dev/null | grep __STDC_VERSION__ | cut -f 3 -d ' '
)

"$mcpp_bin" -@std -V$clang_version "${args[@]}" "${clang_sys_includes[@]}" \
  "${extra_macros[@]}" "$input" > "$output"
