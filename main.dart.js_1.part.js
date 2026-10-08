((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,B={
bav(){return new B.q3(null)},
q3:function q3(d){this.a=d},
a3t:function a3t(d){var _=this
_.d=d
_.e=null
_.f=!0
_.c=_.a=null},
aJs:function aJs(d){this.a=d},
aJt:function aJt(d,e){this.a=d
this.b=e},
aJu:function aJu(d,e){this.a=d
this.b=e},
aJv:function aJv(d,e){this.a=d
this.b=e},
aJw:function aJw(d){this.a=d},
aJx:function aJx(d,e){this.a=d
this.b=e}},D,E
J=c[1]
A=c[0]
C=c[2]
B=a.updateHolder(c[3],B)
D=c[7]
E=c[6]
B.q3.prototype={
Y(){return new B.a3t(A.b([],y.k))}}
B.a3t.prototype={
af(){this.av()
this.x7()},
x7(){var x=0,w=A.t(y.v),v,u=2,t=[],s=this,r,q,p,o,n,m,l,k
var $async$x7=A.u(function(d,e){if(d===1){t.push(e)
x=u}for(;;)switch(x){case 0:s.J(new B.aJs(s))
u=4
n=s.c
n.toString
m=y.b
x=7
return A.m(A.a5(n,!1,y.j).kh("/collections/users/records",A.ac(["page",1,"perPage",50,"sort","code"],y.w,m),m),$async$x7)
case 7:r=e
q=r.a
p=y.B.b(q)&&y.i.b(q.h(0,"items"))?y.i.a(q.h(0,"items")):C.cL
if(s.c==null){x=1
break}s.J(new B.aJt(s,p))
u=2
x=6
break
case 4:u=3
k=t.pop()
n=A.a0(k)
if(n instanceof A.d_){o=n
if(s.c==null){x=1
break}s.J(new B.aJu(s,o))}else throw k
x=6
break
case 3:x=2
break
case 6:case 1:return A.q(v,w)
case 2:return A.p(t.at(-1),w)}})
return A.r($async$x7,w)},
wX(d,e){return this.aqD(d,e)},
aqD(d,e){var x=0,w=A.t(y.v),v,u=2,t=[],s=this,r,q,p,o,n
var $async$wX=A.u(function(f,g){if(f===1){t.push(g)
x=u}for(;;)switch(x){case 0:u=4
q=s.c
q.toString
p=y.w
x=7
return A.m(A.a5(q,!1,y.j).r1("/collections/users/records/"+d,A.ac(["role",e],p,p),y.b),$async$wX)
case 7:x=8
return A.m(s.x7(),$async$wX)
case 8:u=2
x=6
break
case 4:u=3
n=t.pop()
q=A.a0(n)
if(q instanceof A.d_){r=q
if(s.c==null){x=1
break}s.J(new B.aJv(s,r))}else throw n
x=6
break
case 3:x=2
break
case 6:case 1:return A.q(v,w)
case 2:return A.p(t.at(-1),w)}})
return A.r($async$wX,w)},
E(d){var x,w,v,u,t,s,r,q,p,o,n,m,l,k=this,j=null,i=y.u,h=A.ec(A.b([A.bN(j,j,C.d7,j,j,new B.aJw(d),j,j,"\u041d\u0430 \u0433\u043b\u0430\u0432\u043d\u0443\u044e")],i),j,E.CB)
i=A.b([D.a03,C.aH],i)
if(k.f)i.push(C.bK)
x=k.e
if(x!=null)i.push(A.X(x,j,j,j,A.fu(j,j,A.J(d).ax.fy,j,j,j,j,j,j,j,j,j,j,j,j,j,j,!0,j,j,j,j,j,j,j,j),j,j,j))
for(x=k.d,w=x.length,v=y.w,u=y.E,t=y.D,s=0;s<x.length;x.length===w||(0,A.E)(x),++s){r=x[s]
q=A.X(A.k(r.h(0,"fullName")),j,j,j,j,j,j,j)
p=A.X(A.k(r.h(0,"username")),j,j,j,j,j,j,j)
o=A.k(r.h(0,"role"))
n=A.b([],t)
for(m=0;m<3;++m){l=D.LI[m]
n.push(new A.d0(l.b,A.X(A.b0h(l),j,j,j,j,j,j,j),C.aC,j,u))}i.push(A.lm(!1,j,j,j,!0,j,j,j,!0,j,j,j,j,j,j,j,!1,j,j,j,j,p,j,q,A.aUW(n,new B.aJx(k,r),o,v),j))}return A.dJ(h,A.hB(i,C.cH,j,!1),j)}}
var z=a.updateTypes([])
B.aJs.prototype={
$0(){var x=this.a
x.f=!0
x.e=null},
$S:0}
B.aJt.prototype={
$0(){var x,w,v,u,t,s,r,q,p,o=this.a,n=A.b([],y.k)
for(w=J.aK(this.b),v=y.B,u=y.w,t=y.b;w.q();){x=w.gI()
if(v.b(x)){s=x.h(0,"id")
r=x.h(0,"fullName")
if(r==null)r=""
q=x.h(0,"email")
if(q==null)q=""
p=x.h(0,"role")
J.cV(n,A.ac(["pbId",s,"fullName",r,"username",q,"role",p==null?"buyer":p],u,t))}}o.d=n
o.f=!1},
$S:0}
B.aJu.prototype={
$0(){var x=this.a
x.e=A.qL(this.b).k(0)
x.f=!1},
$S:0}
B.aJv.prototype={
$0(){return this.a.e=A.qL(this.b).k(0)},
$S:0}
B.aJw.prototype={
$0(){return A.aq(this.a).au("/",null)},
$S:0}
B.aJx.prototype={
$1(d){if(d!=null&&d!==this.b.h(0,"role"))this.a.wX(A.k(this.b.h(0,"pbId")),d)},
$S:46};(function inheritance(){var x=a.inherit,w=a.inheritMany
x(B.q3,A.T)
x(B.a3t,A.U)
w(A.w4,[B.aJs,B.aJt,B.aJu,B.aJv,B.aJw])
x(B.aJx,A.l_)})()
A.aRO(b.typeUniverse,JSON.parse('{"q3":{"T":[],"e":[]},"a3t":{"U":["q3"]}}'))
var y=(function rtii(){var x=A.at
return{j:x("a9u"),E:x("d0<j>"),D:x("w<d0<j>>"),k:x("w<ao<j,@>>"),u:x("w<e>"),i:x("R<@>"),B:x("ao<@,@>"),w:x("j"),b:x("@"),v:x("~")}})();(function constants(){var x=a.makeConstList
D.LI=x([C.ko,C.hB,C.hC],A.at("w<vB>"))
D.a03=new A.aC("\u042d\u0442\u043e\u0442 \u044d\u043a\u0440\u0430\u043d \u0435\u0441\u0442\u044c \u0442\u043e\u043b\u044c\u043a\u043e \u0443 \u0430\u0434\u043c\u0438\u043d\u0438\u0441\u0442\u0440\u0430\u0442\u043e\u0440\u0430: \u0441\u043c\u0435\u043d\u0430 \u0440\u043e\u043b\u0435\u0439 \u0434\u0440\u0443\u0433\u0438\u0445 \u0443\u0447\u0451\u0442\u043d\u044b\u0445 \u0437\u0430\u043f\u0438\u0441\u0435\u0439.",null,null,null,null,null,null,null,null,null)})()};
(a=>{a["g/uXrXMZIvFHxro1UTlhdlakHMM="]=a.current})($__dart_deferred_initializers__);