char* ltrim(string s) {
  if(!s) return NULL;

  char* c = (char*)s;
  while(*c && *c == ' ') c++;
  return c;
}

char* rtrim(char s[]) {
  if(!s) return NULL;

  for(size_t i = strlen(s); 0 < i; i--)
    if(s[i - 1] != ' ') {
      s[i] = 0;
      break;
    }
  return s;
}

string trim(string s) {
  return rtrim(ltrim(s));
}

char* trim_rn(char s[]) {
  if(!s) return NULL;

  size_t len = strlen(s);
  if(len >= 2 && !strcmp(s + len - 2, "\r\n"))
    s[len - 2] = 0;
  return s;
}

char* touppers(char s[]) {
  if(!s) return NULL;

  size_t len = strlen(s);
  for(size_t i = 0; i < len; i++)
    s[i] = toupper(s[i]);
  return s;
}

char* tolowers(char s[]) {
  if(!s) return NULL;

  size_t len = strlen(s);
  for(size_t i = 0; i < len; i++)
    s[i] = tolower(s[i]);
  return s;
}
