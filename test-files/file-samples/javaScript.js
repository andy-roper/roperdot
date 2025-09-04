// Poorly formatted JavaScript file for testing formatters
const users=[{name:"John",age:25,email:'john@example.com'},{name:'Jane',age:30,email:"jane@example.com"}]

function getUserById(id){
if(!id)return null
    for(let i=0;i<users.length;i++){
if(users[i].id===id){
return users[i]
}
    }
return null}

var calculateTotal = function(items) {
let total= 0;
  for (const item of items) {
total+=item.price*item.quantity
}
    return total
};

class ShoppingCart{
constructor(){
this.items=[]
this.discount=0
}

addItem(name,price,quantity){
if(!name||price<=0||quantity<=0)throw new Error("Invalid item parameters")
this.items.push({name:name,price:price,quantity:quantity})
}

  removeItem(name) {
this.items = this.items.filter(item => item.name !== name)
  }

getTotal(){
const subtotal=calculateTotal(this.items)
return subtotal-(subtotal*this.discount/100)
}
}

// Async function with poor formatting
async function fetchUserData(userId){
try{
const response=await fetch(`/api/users/${userId}`)
if(!response.ok)throw new Error('Failed to fetch user')
const userData=await response.json()
return userData
}catch(error){
console.error("Error fetching user data:",error)
return null
}}

// Arrow function with inconsistent formatting
const processOrder=(order)=>{
if(!order||!order.items||order.items.length===0){
return{success:false,message:'Invalid order'}
}

const cart=new ShoppingCart()
order.items.forEach(item=>{
cart.addItem(item.name,item.price,item.quantity)
})

return{
success:true,
total:cart.getTotal(),
itemCount:order.items.length
}
}

// Object with poor formatting
const config={
apiUrl:'https://api.example.com',
timeout:5000,
retries:3,features:{
enableLogging:true,
enableCache:false,
enableAnalytics:true
},
endpoints:{
users:'/users',
orders:'/orders',
products:'/products'
}}

// Mixed declaration styles and spacing
let isLoggedIn=false,userName='',userRole='guest';

function login(username,password){
if(username==='admin'&&password==='password123'){
isLoggedIn=true
userName=username
userRole='admin'
return true
}else if(username&&password){
isLoggedIn=true
userName=username
userRole='user'
return true
}
return false
}

// Poorly formatted conditionals and loops
for(let i=0;i<users.length;i++){
if(users[i].age>18&&users[i].email.includes('@')){
console.log(`Valid user: ${users[i].name}`)
}else{
console.log('Invalid user')
}
}

// Event handler with poor formatting
document.addEventListener('DOMContentLoaded',function(){
const button=document.getElementById('submit-btn')
if(button){
button.addEventListener('click',function(e){
e.preventDefault()
const form=document.querySelector('form')
if(form){
const formData=new FormData(form)
processOrder({
items:[{
name:formData.get('itemName'),
price:parseFloat(formData.get('price')),
quantity:parseInt(formData.get('quantity'))
}]
})
}
})
}
})

// Export with poor formatting
module.exports={getUserById,calculateTotal,ShoppingCart,fetchUserData,processOrder,config,login}