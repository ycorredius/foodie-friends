import { useEffect, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import axios from "axios";

export default function RecipeLayout() {
  const navigate = useNavigate()
  const [accessToken, setAccessToken] = useState(null)

  useEffect(() => {
    if (localStorage.getItem('accessToken')) {
      setAccessToken(true)
    }else {
      setAccessToken(false)
    }
  }, [])
  const logout = async () => {
   await axios.delete('http://localhost:3001/auth/sign_out.json', 
          {accessToken: localStorage.getItem('accessToken')})
          .then((res) => {
            if (res.status === 200 && res.statusText === "OK") {
              localStorage.removeItem('accessToken')
              navigate('/recipes')
              setAccessToken(!accessToken)
            }else {
              console.log(res.data.errors)
            }
          })
  }

  return(
    <>
    <nav id="main-nav" className="flex justify-between m-4">
      <div></div>
      <div className="flex justify-around">
        <NavLink to="/recipes" className="px-4 my-2">Recipes</NavLink>
        <NavLink to="/recipes/new" className="px-4 my-2" >New Recipe</NavLink>
      </div>
      <div>
        {
          accessToken ? 
            (<a onClick={logout} id="logout">Logout</a>) : 
            (<NavLink to="/login">Login</NavLink>)
        }
      </div>
    </nav>
    <div id="main-content">
      <Outlet/>
    </div>
    </>
  )
}