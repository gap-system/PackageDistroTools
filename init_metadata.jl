# Create the initial contents of `PackageDistro`.
using SHA
using JSON
using DataStructures
using HTTP

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
    sha = open(localpath) do f
            sha256(f)
          end
    push!(info[pkgname], "Sha256" => bytes2hex(sha))
    isdir(pkgname) || mkdir(pkgname)
    formattedstr = json(info[pkgname], 2)
    write("$pkgname/$pkgname.json", formattedstr)
    rm(localpath)
  else
    println("file $arch not found")
  end
end
