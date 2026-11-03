// CI trigger: build all ports from current normal gateway sources; keep main untouched.
// Prime Void Hub | PRE-OBFUSCATED UNIVERSAL TEST builds.
// Downloads live sources from existing gateways, applies ALL regular loader
// source transformations OFFLINE, then protects the results with local Obscura.
// The normal gateway files, main/Loader.lua and base sources never change.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import cp from "node:child_process";
import crypto from "node:crypto";

const repo=process.cwd();
const outputDir=path.join(repo,"obfuscated");
const work=fs.mkdtempSync(path.join(os.tmpdir(),"pvh-obf-"));
fs.mkdirSync(outputDir,{recursive:true});
const mainLoader=fs.readFileSync(path.join(repo,"Loader.lua"),"utf8");
const cutoff=mainLoader.indexOf("local chunk,compileError=loadstring(source)");
if(cutoff<0)throw Error("Unknown main Loader.lua transformation boundary");
const precompile=mainLoader.slice(0,cutoff);
const expected={
 storm:["SOURCE GITHUB v","Prime Void Hub - Storm Suite"],
 huntress:["Prime Void Hub - Huntress","PVHuntressUnload"],
 exu:["local rarityList=","Prime Void | Exu Security Lab"],
 destruction:["-- Obscura ["],
 splash:["-- Prime Void Hub - Dont Splash","PVDontSplashUnload"],
};
const ports=[
 ["storm",12593620250,"https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua"],
 ["huntress",104259439179020,"https://prime-void-hub-huntress-gateway.vercel.app/huntress.lua"],
 ["exu",103076400317371,"https://prime-void-hub-exu-gateway.vercel.app/exu-security-lab.lua"],
 ["destruction",2248408710,"https://prime-void-hub-destruction-gateway.vercel.app/destruction-simulator.lua"],
 ["splash",139386728420706,"https://prime-void-hub-splash-gateway.vercel.app/dont-splash.lua"],
];
const run=(bin,args,settings={})=>{
 const res=cp.spawnSync(bin,args,{encoding:"utf8",timeout:180000,maxBuffer:25000000,...settings});
 if(res.error||res.status!==0){
   throw Error([bin,...args].join(" ")+" failed "+res.status+": "
     +String(res.error?.message||res.stderr||res.stdout).slice(0,3000));
 }
 return res.stdout;
};
function writeSim(name,placeId,raw){
 let eq="=";
 while(raw.includes("]"+eq+"]")) eq+="=";
 const prefix="local __raw=["+eq+"["+raw+"]"+eq+"]\n"
   +"game={PlaceId="+placeId+",GameId=0,HttpGet=function()return __raw end,"
   +"GetService=function()return {} end}\n"
   +"getgenv=function()return {} end\n";
 const sim=prefix+precompile+
  "\nprint('__PVH_OBF_BUILD_START__')\nprint(source)\nprint('__PVH_OBF_BUILD_END__')\n";
 const file=path.join(work,"build-"+name+".luau");
 fs.writeFileSync(file,sim);
 const printed=run(process.env.LUAU_RUNTIME||"/tmp/luau/luau",[file]);
 const open="__PVH_OBF_BUILD_START__\n",close="\n__PVH_OBF_BUILD_END__";
 const from=printed.indexOf(open),to=printed.indexOf(close,from+open.length);
 if(from<0||to<0)throw Error("Patch simulator did not capture "+name);
 return printed.slice(from+open.length,to);
}
function assertCompile(name,source){
 const file=path.join(work,name);
 fs.writeFileSync(file,source);
 run(process.env.LUAU_COMPILER||"/tmp/luau/luau-compile",["--binary",file],{encoding:null});
 return file;
}
function hash(content){return crypto.createHash("sha256").update(content).digest("hex")}
async function download(url){
 const response=await fetch(url,{signal:AbortSignal.timeout(25000)});
 if(!response.ok)throw Error("Gateway returned HTTP "+response.status+" at "+url);
 const data=await response.text();
 if(data.length<800)throw Error("Gateway returned unexpectedly short source: "+url);
 return data;
}
async function build(){
 const manifest={
  label:"Prime Void Hub | All Obfuscated Test",
  generatedAt:new Date().toISOString(),
  tool:"vo3pal/obscura@742770554151d82c6a12ae6e24a0e47471bc467c",
  profile:"native",
  base:"main sources read-only; test-only output",
  entries:{}
 };
 for(const [name,placeId,url] of ports){
   const source=await download(url);
   for(const marker of expected[name]){
     if(!source.includes(marker))throw Error("Missing gateway source signature for "+name+": "+marker);
   }
   const transformed=writeSim(name,placeId,source);
   if(!transformed||transformed.length<800)throw Error("Invalid patched source "+name);
   if(name==="exu" && (!transformed.includes("farmGifts:AddToggle('PVEXU_GiftsCollect'")
      || !transformed.includes("farmGifts:AddToggle('PVEXU_GiftsHop'"))) {
     throw Error("Exu gift Obsidian controls were not applied before obfuscation");
   }
   assertCompile("patched-"+name+".lua",transformed);
   let build;
   if(name==="destruction"){
     // Already an Obscura build; avoid wrapping its protected VM again.
     build=transformed;
   }else{
     const input=path.join(work,"patched-"+name+".lua");
     const target=path.join(work,"obf-"+name+".lua");
     run("python3",[
       process.env.OBSCURA_MAIN||"/tmp/obscura/main.py",
       input,"--mode","native","-o",target
     ]);
     build=fs.readFileSync(target,"utf8");
   }
   if(!build.includes("-- Obscura ["))throw Error("Missing Obscura header for "+name);
   assertCompile("check-"+name+".lua",build);
   const dest=path.join(outputDir,name+".lua");
   fs.writeFileSync(dest,build);
   manifest.entries[name]={
     path:"obfuscated/"+name+".lua",
     sourceUrl:url,
     sourceSha256:hash(source),
     patchedSha256:hash(transformed),
     obfuscatedSha256:hash(build),
     bytes:Buffer.byteLength(build),
     profile:name==="destruction"?"existing Obscura VM":"Obscura native",
   };
   console.log(name+": transformed="+Buffer.byteLength(transformed)
     +" obfuscated="+Buffer.byteLength(build)+" sha256="+hash(build).slice(0,12));
 }
 const gifts=fs.readFileSync(path.join(repo,"Exu_Gifts_Main.lua"),"utf8");
 if(!gifts.includes('InvokeServer("gift",index)'))throw Error("Exu gifts contract changed");
 assertCompile("raw-exu-gifts.lua",gifts);
 const giftIn=path.join(work,"raw-exu-gifts.lua");
 const giftOut=path.join(work,"obf-exu-gifts.lua");
 run("python3",[
   process.env.OBSCURA_MAIN||"/tmp/obscura/main.py",
   giftIn,"--mode","native","-o",giftOut
 ]);
 const obfGifts=fs.readFileSync(giftOut,"utf8");
 assertCompile("check-exu-gifts.lua",obfGifts);
 if(!obfGifts.includes("-- Obscura ["))throw Error("Exu gifts output was not obfuscated");
 fs.writeFileSync(path.join(outputDir,"exu-gifts.lua"),obfGifts);
 manifest.entries["exu-gifts"]={
   path:"obfuscated/exu-gifts.lua",
   sourceSha256:hash(gifts),
   obfuscatedSha256:hash(obfGifts),
   bytes:Buffer.byteLength(obfGifts),
   profile:"Obscura native",
 };
 fs.writeFileSync(path.join(outputDir,"manifest.json"),
   JSON.stringify(manifest,null,2)+"\n");
 console.log("SUCCESS: All five game ports plus Exu gifts compiled.");
}
build().catch(err=>{console.error("BUILD FAILED:",err.stack||err);process.exitCode=1});
