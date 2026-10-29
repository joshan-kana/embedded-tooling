{
  script = /* bash */ ''
    if true;then
    echo hi
    fi
  '';
  untouched = /* python */ ''
    print( 42 )
  '';
}
