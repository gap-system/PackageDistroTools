# Create the initial contents of `PackageDistro`.
using CodecZlib
using DataStructures
using HTTP
using JSON
using SHA
using Tar

info = read(expanduser("~/package-infos.json"), String)
info = JSON.parse(info; dicttype = SortedDict)

for pkgname in collect(keys(info))
println(pkgname)
  url = info[pkgname]["PackageInfoURL"]
  format = split(info[pkgname]["ArchiveFormats"], " ")[1]
  arch = info[pkgname]["ArchiveURL"]*format
  req = HTTP.request("GET", arch; verbose = 0, status_exception = false);
  if req.status == 200
    downl = String(req.body)
    localpath = basename(arch)
    write(localpath, downl)
    archivesha = open(localpath) do f
            sha256(f)
          end

    tar_gz = open(localpath)
    tar = GzipDecompressorStream(tar_gz)
    # dir = Tar.extract(tar, "tmpdir") # does not work on some archives ...
    # list = Tar.list(tar, strict = false) # does not work on some archives ...
    # dirnam = list[1].path
    io = IOBuffer()
    if endswith(localpath, ".zip")
#T ugly hack
      run(pipeline(`unzip -ql $localpath`, stdout = io))
      str = String(take!(io))
      spl = split( str, "\n")
      dirnam = spl[3]
      dirnam = dirnam[(findlast(' ', dirnam)+1):(findfirst('/', dirnam)-1)]
      cmd = `unzip $localpath $dirnam/PackageInfo.g`
    else
      run(pipeline(`tar tf $localpath`, stdout = io))
      str = String(take!(io))
      spl = split( str, "\n")
      dirnam = spl[1]
      dirnam = dirnam[1:(findfirst('/', dirnam)-1)]
      cmd = `tar xf $localpath $dirnam/PackageInfo.g` # do not use `xvzf`!
    end
    run(cmd)
    close(tar)
    pkginfopath = joinpath(dirnam, "PackageInfo.g")
    packageinfosha = open(pkginfopath) do f
            sha256(f)
          end
    push!(info[pkgname], "ArchiveSha256" => bytes2hex(archivesha))
    push!(info[pkgname], "PackageInfoSha256" => bytes2hex(packageinfosha))
    rm(dirnam, recursive = true)
    isdir(pkgname) || mkdir(pkgname)
    formattedstr = json(info[pkgname], 2)
    write("$pkgname/meta.json", formattedstr)
    rm(localpath)
  else
    println("file $arch not found")
  end
end
